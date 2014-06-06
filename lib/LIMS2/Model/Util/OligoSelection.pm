package LIMS2::Model::Util::OligoSelection;

use strict;
use warnings;

=head1 NAME

LIMS2::Model::Util::OligoSelection

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw(
        gibson_design_oligos_rs
        oligos_for_gibson
        oligos_for_crispr_pair
        pick_crispr_primers
        pick_single_crispr_primers
        retrieve_crispr_primers
        get_genotyping_primer_extent
    ) ]
};

use LIMS2::Exception;

use Log::Log4perl qw(:easy);


BEGIN {
    # LIMS2 environment variables start with LIMS2_
    # but DesignCreate needs 'PRIMER3_CMD'
    local $ENV{'PRIMER3_CMD'} = $ENV{'LIMS2_PRIMER3_COMMAND_PATH'};
}
use DesignCreate::Util::Primer3;
use DesignCreate::Util::BWA;
use LIMS2::Model::Util::DesignInfo;

use Bio::SeqIO;
use Path::Class;
use Bio::EnsEMBL::Registry;

my $registry = 'Bio::EnsEMBL::Registry';

$registry->load_registry_from_db(
        -host => $ENV{LIMS2_ENSEMBL_HOST} || 'ensembldb.internal.sanger.ac.uk',
        -user => $ENV{LIMS2_ENSEMBL_USER} || 'anonymous'
    );



=head pick_PCR_primers_for_crisprs
    given location of crispr primers as an input,
    search for primers to generate a PCR product covering the region of the crispr primers
    This is modeled on the genotyping primers and therefore includes a genomic check
=cut


sub pick_crispr_PCR_primers {
    my $params = shift;

    my $schema = $params->{'schema'};
    my $well_id = $params->{'well_id'};
    my $crispr_primers = $params->{'crispr_primers'};
    my $species = $params->{'species'};
    my $repeat_mask = $params->{'repeat_mask'};
    # Return the design oligos as well so that we can report them to provide context later on
    my ($region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_seq_start )
        = get_crispr_PCR_EnsEmbl_region( {
                schema => $schema,
                crispr_primers => $crispr_primers,
                species => $species,
                repeat_mask => $repeat_mask,
            } );
    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_PCR_CRISPR_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length + 500),
    );
    my $dir_out = dir( $ENV{ 'LIMS2_PRIMER_SELECTION_DIR' } );
    my $logfile = $dir_out->file( $well_id . '_pcr_oligos.log');

    my ( $result, $primer3_explain ) = $p3->run_primer3( $logfile->absolute, $region_bio_seq, # bio::seqI
            {
                SEQUENCE_TARGET => $target_sequence_mask ,
            } );
    my $primer_data;
    my $primer_passes;
    if ( $result->num_primer_pairs ) {
        INFO ( "$well_id pcr primer region primer pairs: " . $result->num_primer_pairs );
        $primer_data = parse_primer3_results( $result );
        $primer_passes = pcr_genomic_check( $well_id, $species, $primer_data );
    }
    else {
        INFO ( "Failed to generate pcr primer pairs for $well_id" );
        INFO ( 'Primer3 reported: ');
        INFO ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        INFO ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
    }

    #TODO: If no primer pairs pass the genomic check, need to call this method recursively with a different
    #set of parameters until two pairs of primers are found.

    return ($primer_data, $primer_passes, $chr_seq_start);
}

=head pick_genotyping_primers
     outline of process:
     query the design_oligos table for the design_id and the 5F or 3R primer,
     join on the design_oligo_loci table to generate the genomic co-ordinates
     Construct an input file for EnsEmbl to pull back the sequence for the region
     call Primer 3 with appropriate options to generate primers.
     update the genotyping oligos table with the generated oligos.
=cut

sub pick_genotyping_primers {
    my $params = shift;

    my $schema = $params->{'schema'};
    my $design_id = $params->{'design_id'};
    my $well_id = $params->{'well_id'};
    my $species = $params->{'species'};
    my $repeat_mask = $params->{'repeat_mask'};

    # Return the design oligos as well so that we can report them to provide context later on
    my ($region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_strand, $design_oligos, $chr_seq_start)
        = get_genotyping_EnsEmbl_region( {
                schema => $schema,
                design_id => $design_id,
                repeat_mask => $repeat_mask,
            } );

    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_GIBSON_GENOTYPING_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length + 500),
    );

    my $dir_out = dir( $ENV{ 'LIMS2_PRIMER_SELECTION_DIR' } );
    my $logfile = $dir_out->file( $design_id . '_oligos.log');

    my ( $result, $primer3_explain ) = $p3->run_primer3( $logfile->absolute, $region_bio_seq, # bio::seqI
            { SEQUENCE_TARGET => $target_sequence_mask ,
            } );
    my $primer_data;
    my $primer_passes;
    if ( $result->num_primer_pairs ) {
        INFO ( "$design_id genotyping primer region primer pairs: " . $result->num_primer_pairs );
        $primer_data = parse_primer3_results( $result );
        $primer_passes = genomic_check( $design_id, $well_id, $species, $primer_data, $chr_strand );
    }
    else {
        INFO ( "Failed to generate genotyping primer pairs for $design_id" );
        INFO ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        INFO ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
    }

    return ($primer_data, $primer_passes, $chr_strand, $design_oligos, $chr_seq_start);
}

sub pcr_genomic_check {
    my $well_id = shift;
    my $species = shift;
    my $primer_data = shift;


    # implement genomic specificity checking using BWA
    #

    my ($bwa_query_filespec, $work_dir ) = generate_pcr_bwa_query_file( $well_id, $primer_data );
    my $num_bwa_threads = 2;


    my $bwa = DesignCreate::Util::BWA->new(
            query_file        => $bwa_query_filespec,
            work_dir          => $work_dir,
            species           => $species,
            three_prime_check => 0,
            num_bwa_threads   => $num_bwa_threads,
    );

    $bwa->generate_sam_file;
    my $oligo_hits = $bwa->oligo_hits;
    $primer_data = filter_oligo_hits( $oligo_hits, $primer_data );

    return $primer_data;

}


sub genomic_check {
    my $design_id = shift;
    my $well_id = shift;
    my $species = shift;
    my $primer_data = shift;


    # implement genomic specificity checking using BWA
    #

    my ($bwa_query_filespec, $work_dir ) = generate_bwa_query_file( $design_id, $well_id, $primer_data );
    my $num_bwa_threads = 2;


    my $bwa = DesignCreate::Util::BWA->new(
            query_file        => $bwa_query_filespec,
            work_dir          => $work_dir,
            species           => $species,
            three_prime_check => 0,
            num_bwa_threads   => $num_bwa_threads,
    );

    $bwa->generate_sam_file;
    my $oligo_hits = $bwa->oligo_hits;
    $primer_data = filter_oligo_hits( $oligo_hits, $primer_data );

    return $primer_data;

}


sub filter_oligo_hits {
    my $hits_to_filter = shift;
    my $primer_data = shift;

    # select only the primers with highest rank
    # that are not hitting other areas of the genome

    # so that we only suggest max of two primer pairs.

    foreach my $key ( sort keys %{$primer_data->{'left'}} ) {
        $primer_data->{'left'}->{$key}->{'mapped'} = $hits_to_filter->{$key};
    }

    foreach my $key ( sort keys %{$primer_data->{'right'}} ) {
        $primer_data->{'right'}->{$key}->{'mapped'} = $hits_to_filter->{$key};
    }

    $primer_data = del_bad_pairs('left', $primer_data);
    $primer_data = del_bad_pairs('right', $primer_data);

    return $primer_data;
}

=head del_bad_pairs
Given: left | right, primer_data hashref
Returns: primer_data_hashref

     Process the input hash deleting any that do not have a unique_alignment key.
     Make sure there both a left and a right primer of the same rank.

=cut
sub del_bad_pairs {
    my $primer_end = shift;
    my $primer_data = shift;

    my $temp1;
    my $temp2;

    foreach my $primer ( sort keys %{$primer_data->{$primer_end}} ) {
        if ( ! defined $primer_data->{$primer_end}->{$primer}->{'mapped'}->{'unique_alignment'} ) {
            $primer =~ s/right/left/;
            my $left_primer = $primer;
            $primer =~ s/left/right/;
            my $right_primer = $primer;
            $temp1 = delete $primer_data->{'left'}->{$left_primer};
            $temp2 = delete $primer_data->{'right'}->{$right_primer};
        }
    }
    return $primer_data;
}

sub generate_pcr_bwa_query_file {
    my $well_id = shift;
    my $primer_data = shift;

    my $root_dir = $ENV{ 'LIMS2_BWA_OLIGO_DIR' } // '/var/tmp/bwa';
    use Data::UUID;
    my $ug = Data::UUID->new();

    my $unique_string = $ug->create_str();
    my $dir_out = dir( $root_dir, '_' . $well_id . $unique_string );
    mkdir $dir_out->stringify  or die 'Could not create directory ' . $dir_out->stringify . ": $!";

    my $fasta_file_name = $dir_out->file( $well_id . '_oligos.fasta');
    my $fh = $fasta_file_name->openw();
    my $seq_out = Bio::SeqIO->new( -fh => $fh, -format => 'fasta' );

    foreach my $oligo ( sort keys %{ $primer_data->{'left'} } ) {
        my $fasta_seq = Bio::Seq->new( -seq => $primer_data->{'left'}->{$oligo}->{'seq'}, -id => $oligo );
        $seq_out->write_seq( $fasta_seq );
    }

    foreach my $oligo ( sort keys %{ $primer_data->{'right'} } ) {
        my $fasta_seq = Bio::Seq->new( -seq => $primer_data->{'right'}->{$oligo}->{'seq'}, -id => $oligo );
        $seq_out->write_seq( $fasta_seq );
    }

    return ($fasta_file_name, $dir_out);
}


sub generate_bwa_query_file {
    my $design_id= shift;
    my $well_id = shift;
    my $primer_data = shift;

    my $root_dir = $ENV{ 'LIMS2_BWA_OLIGO_DIR' } // '/var/tmp/bwa';
    use Data::UUID;
    my $ug = Data::UUID->new();

    my $unique_string = $ug->create_str();
    my $dir_out = dir( $root_dir, '_' . $well_id . $unique_string );
    mkdir $dir_out->stringify  or die 'Could not create directory ' . $dir_out->stringify . ": $!";

    my $fasta_file_name = $dir_out->file( $design_id . '_oligos.fasta');
    my $fh = $fasta_file_name->openw();
    my $seq_out = Bio::SeqIO->new( -fh => $fh, -format => 'fasta' );

    foreach my $oligo ( sort keys %{ $primer_data->{'left'} } ) {
        my $fasta_seq = Bio::Seq->new( -seq => $primer_data->{'left'}->{$oligo}->{'seq'}, -id => $oligo );
        $seq_out->write_seq( $fasta_seq );
    }

    foreach my $oligo ( sort keys %{ $primer_data->{'right'} } ) {
        my $fasta_seq = Bio::Seq->new( -seq => $primer_data->{'right'}->{$oligo}->{'seq'}, -id => $oligo );
        $seq_out->write_seq( $fasta_seq );
    }

    return ($fasta_file_name, $dir_out);
}


sub parse_primer3_results {
    my $result = shift;

    my $oligo_data;
    # iterate through each primer pair
    $oligo_data->{pair_count} = $result->num_primer_pairs;
    while (my $pair = $result->next_primer_pair) {
        # do stuff with primer pairs...
        my ($fp, $rp) = ($pair->forward_primer, $pair->reverse_primer);
        $oligo_data->{'left'}->{$fp->display_name} = parse_primer( $fp );
        $oligo_data->{'right'}->{$rp->display_name} = parse_primer( $rp );
    }

    return $oligo_data;
}

=head2 parse_primer


=cut
sub parse_primer {
    my $primer = shift;

    my %oligo_data;

    my @primer_attrs = qw/
        length
        melting_temp
        gc_content
        rank
        location
    /;


    %oligo_data = map { $_  => $primer->$_ } @primer_attrs;
    $oligo_data{'seq'} = $primer->seq->seq;

    return \%oligo_data;
}

sub primer_driver {
    my %params;

    $params{'schema'} = shift;
    $params{'design_id'} = shift;
    $params{'assembly'} = shift;

    my $design_oligos = oligos_for_gibson( \%params );

    return;
}

=head2 oligos_for_gibson

Generate genotyping primer oligos for a design.

Given: Design id
Returns: Arrayref of 4 primers

find the 5F primer location
get the sequence of the 5' 1kb
Use Primer3 to generate primers.
Select two primers that meet the criteria

Perform this trick for 3R + 1kb

The result should be 4 primers.

=cut

sub oligos_for_gibson {
    my $params = shift;

    my $gibson_design_oligos_rs = gibson_design_oligos_rs( $params->{'schema'}, $params->{'design_id'} );
    my %genotyping_primers;
    update_primer_type( '5F', \%genotyping_primers, $gibson_design_oligos_rs, $params->{'assembly'});
    update_primer_type( '3R', \%genotyping_primers, $gibson_design_oligos_rs, $params->{'assembly'});

    return \%genotyping_primers;
}


=head2
Given - design_id

Returns - hashref of two sequences to find primers in.

=cut

sub get_EnsEmbl_sequence {
    my $params = shift;

    my $design_r = $params->{'schema'}->resultset('Design')->find($params->{'design_id'});
    my $design_info = LIMS2::Model::Util::DesignInfo->new( design => $design_r );
    my $design_oligos = $design_info->oligos;

    my $chr_strand = $design_info->chr_strand eq '1' ? 'plus' : 'minus';
    my $slice_5R;
    my $slice_3F;
    my %seqs;

    if ( $chr_strand eq 'plus' ) {
        $slice_5R = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{'5R'}->{'start'} - 1001,
            $design_oligos->{'5R'}->{'start'} - 1,
            $design_info->chr_strand,
        );
        $slice_3F = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{'3F'}->{'start'} + 1,
            $design_oligos->{'3F'}->{'start'} + 1001,
            $design_info->chr_strand,
        );
        $seqs{'Forward'} = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_5R->seq, -verbose => -1 );
        $seqs{'Reverse'} = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_3F->seq, -verbose => -1 )->revcom;
    }
    elsif ( $chr_strand eq 'minus' ) {
        $slice_5R = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{'3F'}->{'start'} - 1001,
            $design_oligos->{'3F'}->{'start'} - 1,
            $design_info->chr_strand,
        );
        $slice_3F = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{'5R'}->{'start'} + 1,
            $design_oligos->{'5R'}->{'start'} + 1001,
            $design_info->chr_strand,
        );
        $seqs{'Reverse'} = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_5R->seq, -verbose => -1 )->revcom;
        $seqs{'Forward'} = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_3F->seq, -verbose => -1 );
    }


    return \%seqs ;

}

=head
Given crispr sequencing co-ordinates
Returns a sequence region
=cut

sub get_crispr_PCR_EnsEmbl_region{
    my $params = shift;

    my $schema = $params->{'schema'};
    my $crispr_primers = $params->{'crispr_primers'};
    my $species = $params->{'species'};
    my $repeat_mask = $params->{'repeat_mask'};

    my $slice_region;

    # Here we want a slice from the beginning of (start(left_0) - ($dead_width + $search_field))
    # to the end(right_0) + ($dead_width + $search_field)
    my $dead_field_width = 100;
    my $search_field_width = 500;


    my $chr_strand = $crispr_primers->{'strand'}; # That is the gene strand

    my $slice_adaptor = $registry->get_adaptor($species, 'Core', 'Slice');
    my $seq;


    my $start_target = $crispr_primers->{'crispr_primers'}->{'left'}->{'left_0'}->{'location'}->start
        + $crispr_primers->{'crispr_seq'}->{'chr_region_start'} ;
    my $end_target = $crispr_primers->{'crispr_primers'}->{'right'}->{'right_0'}->{'location'}->end
        + $crispr_primers->{'crispr_seq'}->{'chr_region_start'};

    my $start_coord =  $start_target - ($dead_field_width + $search_field_width);
    my $end_coord =  $end_target + ($dead_field_width + $search_field_width);
    $slice_region = $slice_adaptor->fetch_by_region(
        'chromosome',
        $crispr_primers->{'crispr_seq'}->{'left_crispr'}->{'chr_name'},
        $start_coord,
        $end_coord,
        $chr_strand eq 'plus' ? '1' : '-1' ,
    );
    if ( $chr_strand eq 'plus' ) {
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 0,
            });
    }
    elsif ( $chr_strand eq 'minus' ) {
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 0,
            });
    }

    my $target_sequence_length = ($end_target - $start_target) + 2 * $dead_field_width;
    my $target_sequence_string = $search_field_width . ',' . $target_sequence_length;

    my $chr_region_start = $slice_region->start;

    return ( $seq, $target_sequence_string, $target_sequence_length, $chr_region_start );
}


=head
Given design and schema
Returns a single sequence covering the whole region for Primer3 and a target_sequence_string that
indicates which part of the sequence is being targeted (and therefore should not be part of the primer
sequences).
=cut

sub get_genotyping_EnsEmbl_region {
    my $params = shift;

    my $design_r = $params->{'schema'}->resultset('Design')->find($params->{'design_id'});
    my $design_info = LIMS2::Model::Util::DesignInfo->new( design => $design_r );
    my $design_oligos = $design_info->oligos;
    my $repeat_mask = $params->{'repeat_mask'};

    my $chr_strand = $design_info->chr_strand eq '1' ? 'plus' : 'minus';
    my $slice_region;
    my $seq;

    my $start_oligo_field_width = 1000;
    my $end_oligo_field_width = 1000;
    my @oligo_keys = sort keys %$design_oligos; # make sure we always deal with the same keys in the same order
    my $o_start_key = $oligo_keys[0];
    my $o_end_key = $oligo_keys[0];
    # Now find the max and min oligo coords in the oligo set
    foreach my $o_key ( reverse @oligo_keys ) {
        if (exists $design_oligos->{$o_key}) {
            if ( $design_oligos->{$o_key}->{'start'} < $design_oligos->{$o_start_key}->{'start'} ) {
                delete $design_oligos->{$o_start_key} if $o_start_key ne $o_end_key;
                $o_start_key = $o_key;
            }
            elsif ( $design_oligos->{$o_key}->{'end'} > $design_oligos->{$o_end_key}->{'end'} ) {
                delete $design_oligos->{$o_end_key} if $o_end_key ne $o_start_key;
                $o_end_key = $o_key;
            }
            else {
                delete $design_oligos->{$o_key};
            }
        }
    }
    # Now design oligos only contains keys for the max and coord oligos.
    if ( $chr_strand eq 'plus' ) {
        $slice_region = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{$o_start_key}->{'start'} - $start_oligo_field_width,
            $design_oligos->{$o_end_key}->{'end'} + $end_oligo_field_width,
            $design_info->chr_strand,

        );
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 0,
            });
    }
    elsif ( $chr_strand eq 'minus' ) {
        $slice_region = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{$o_start_key}->{'start'} - $start_oligo_field_width,
            $design_oligos->{$o_end_key}->{'end'} + $end_oligo_field_width,
            $design_info->chr_strand,
        );
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 1,
            });
    }

    my $target_sequence_length = $seq->length  - $start_oligo_field_width - $end_oligo_field_width;
    my $target_sequence_string = $start_oligo_field_width . ',' . $target_sequence_length;
    my $chr_region_start = $slice_region->start;

    return ($seq, $target_sequence_string, $target_sequence_length, $chr_strand, $design_oligos, $chr_region_start);

}

=head2 gibson_design_oligos_rs
Given schema, design_id

Returns a DBIC resultset of design oligos
=cut

sub gibson_design_oligos_rs {
    my $schema = shift;
    my $design_id = shift;

    my $design_rs = $schema->resultset('DesignOligo')->search(
        {
            'design_id' => $design_id,
        },
    );

    return $design_rs;

}

=head2 update_primer_type
Given a valid primer name (5F or 3R), a hashref to store result in

returns the given hashref

=cut

sub update_primer_type {
    my $primer_name = shift;
    my $genotyping_primer_hr = shift;
    my $design_rs = shift;
    my $assembly = shift;

    my $refined_rs = $design_rs->search(
        {
            'design_oligo_type_id' =>  $primer_name,
        },
    );

    $refined_rs = $refined_rs->search(
        {
            'loci.assembly_id' => $assembly,
        },
        {
            prefetch => [ 'loci' ],
        },
    );

    my $refined_row = $refined_rs->first;
    if ( ! $refined_row ) {
        LIMS2::Exception->throw( 'No data returned for ' . $primer_name);
        # confess 'No data returned for ' . $primer_name;
    }
    my $locus = $refined_row->loci->first;
    if ( ! $locus ) {
        LIMS2::Exception->throw( 'No locus information available for ' . $primer_name);
    }

    $genotyping_primer_hr->{$primer_name}->{chr_start} = $locus->chr_start;

    return \$genotyping_primer_hr;
}

sub pick_crispr_primers {
    my $params = shift;
    my $repeat_mask = $params->{'repeat_mask'};

    my $crispr_oligos = oligos_for_crispr_pair( $params->{'schema'}, $params->{'crispr_pair_id'} );

    # chr_strand for the gene is required because the crispr primers are named accordingly SF1, SR1
    my ( $region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_strand,
        $chr_seq_start, $chr_seq_end)
        = get_crispr_pair_EnsEmbl_region($params, $crispr_oligos, $repeat_mask );

        # FIXME:do we need this? we now return as a $chr_seq_start separate list item
    $crispr_oligos->{'chr_region_start'} = $chr_seq_start;

    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_CRISPR_SEQUENCING_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length + 500),
    );

    my $dir_out = dir( $ENV{ 'LIMS2_PRIMER_SELECTION_DIR' } );
    my $logfile = $dir_out->file( $params->{'crispr_pair_id'} . '_seq_oligos.log');

    my ( $result, $primer3_explain ) = $p3->run_primer3( $logfile->absolute, $region_bio_seq, # bio::seqI
            { SEQUENCE_TARGET => $target_sequence_mask ,
            } );
    my $primer_data;
    if ( $result->num_primer_pairs ) {
        INFO ( $params->{'crispr_pair_id'} . ' sequencing primers : ' . $result->num_primer_pairs );
        $primer_data = parse_primer3_results( $result );
    }
    else {
        INFO ( 'Failed to generate sequencing primers for ' . $params->{'crispr_pair_id'} );
        INFO ( 'Primer3 reported: ');
        INFO ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        INFO ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
    }

    return ($crispr_oligos, $primer_data, $chr_strand, $chr_seq_start);
}


sub pick_single_crispr_primers {
    my $params = shift;

    my $repeat_mask = $params->{'repeat_mask'};
    my $crispr_oligos = oligo_for_single_crispr( $params->{'schema'}, $params->{'crispr_id'} );

    # chr_strand for the gene is required because the crispr primers are named accordingly SF1, SR1
    my ( $region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_strand,
        $chr_seq_start, $chr_seq_end)
        = get_single_crispr_EnsEmbl_region($params, $crispr_oligos, $repeat_mask );

    $crispr_oligos->{'chr_region_start'} = $chr_seq_start;

    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_CRISPR_SEQUENCING_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length + 500),
    );

    my $dir_out = dir( $ENV{ 'LIMS2_PRIMER_SELECTION_DIR' } );
    my $logfile = $dir_out->file( $params->{'crispr_id'} . '_s_seq_oligos.log');

    my ( $result, $primer3_explain ) = $p3->run_primer3( $logfile->absolute, $region_bio_seq, # bio::seqI
            { SEQUENCE_TARGET => $target_sequence_mask ,
            } );
    my $primer_data;
    if ( $result->num_primer_pairs ) {
        INFO ( $params->{'crispr_id'} . ' sequencing primers : ' . $result->num_primer_pairs );
        $primer_data = parse_primer3_results( $result );
    }
    else {
        INFO ( 'Failed to generate sequencing primers for ' . $params->{'crispr_id'} );
        INFO ( 'Primer3 reported: ');
        INFO ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        INFO ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
    }

    return ($crispr_oligos, $primer_data, $chr_strand, $chr_seq_start);
}

=head2 oligos_for_crispr_pair

Generate sequencing primer oligos for a crispr pair

These oligos should be 100b from the 5' end of the left crispr so that sequencing reads into the crispr itself.

For the right crispr, the primer should be 100b from the 3' end of the crispr, again so that sequencing
reads into the crispr itself

Given crispr pair id
Returns Hash of two oligos forming the left and right crispr pair.

=cut

sub oligos_for_crispr_pair {
    my $schema = shift;
    my $crispr_pair_id = shift;


    my $crispr_pairs_rs = crispr_pair_oligos_rs( $schema, $crispr_pair_id );
    my $crispr_pair = $crispr_pairs_rs->first;

    my %crispr_pairs;
    $crispr_pairs{'left_crispr'}->{'id'} = $crispr_pair->left_crispr_locus->crispr_id;
    $crispr_pairs{'left_crispr'}->{'chr_start'} = $crispr_pair->left_crispr_locus->chr_start;
    $crispr_pairs{'left_crispr'}->{'chr_end'} = $crispr_pair->left_crispr_locus->chr_end;
    $crispr_pairs{'left_crispr'}->{'chr_strand'} = $crispr_pair->left_crispr_locus->chr_strand;
    $crispr_pairs{'left_crispr'}->{'chr_id'} = $crispr_pair->left_crispr_locus->chr_id;
    $crispr_pairs{'left_crispr'}->{'chr_name'} = $crispr_pair->left_crispr_locus->chr->name;
    $crispr_pairs{'left_crispr'}->{'seq'} = $crispr_pair->left_crispr_locus->crispr->seq;

    $crispr_pairs{'right_crispr'}->{'id'} = $crispr_pair->right_crispr_locus->crispr_id;
    $crispr_pairs{'right_crispr'}->{'chr_start'} = $crispr_pair->right_crispr_locus->chr_start;
    $crispr_pairs{'right_crispr'}->{'chr_end'} = $crispr_pair->right_crispr_locus->chr_end;
    $crispr_pairs{'right_crispr'}->{'chr_strand'} = $crispr_pair->right_crispr_locus->chr_strand;
    $crispr_pairs{'right_crispr'}->{'chr_id'} = $crispr_pair->right_crispr_locus->chr_id;
    $crispr_pairs{'right_crispr'}->{'chr_name'} = $crispr_pair->right_crispr_locus->chr->name;
    $crispr_pairs{'right_crispr'}->{'seq'} = $crispr_pair->right_crispr_locus->crispr->seq;

    return \%crispr_pairs;
}

sub crispr_pair_oligos_rs {
    my $schema = shift;
    my $crispr_pair_id = shift;

    my $crispr_rs = $schema->resultset('CrisprPair')->search(
        {
            'id' => $crispr_pair_id,
        },
    );

    return $crispr_rs;
}

=head oligo_for_single_crispr

returns a hr that contains lots fo information on the single crispr under the 'left_crispr' key

Everything else is done wrt crispr pairs, so it is easier to use the same data structures.

=cut

sub oligo_for_single_crispr {
    my $schema = shift;
    my $crispr_id = shift;

    # TODO: should be checking assembly, chromosome and species here

    my $crispr_rs = crispr_oligo_rs( $schema, $crispr_id );
    my $crispr = $crispr_rs->first;

    my %crispr_pairs;
    $crispr_pairs{'left_crispr'}->{'id'} = $crispr->id;
    my $locus_count = $crispr->loci->count;
    if ($locus_count != 1 ) {
        INFO ('Found multiple loci for ' . $crispr_id);
    }
    my $locus = $crispr->loci->first;
    $crispr_pairs{'left_crispr'}->{'chr_start'} = $locus->chr_start;
    $crispr_pairs{'left_crispr'}->{'chr_end'} = $locus->chr_end;
    $crispr_pairs{'left_crispr'}->{'chr_strand'} = $locus->chr_strand;
    $crispr_pairs{'left_crispr'}->{'chr_id'} = $locus->chr_id;
    $crispr_pairs{'left_crispr'}->{'chr_name'} = $locus->chr->name;
    $crispr_pairs{'left_crispr'}->{'seq'} = $crispr->seq;

    return \%crispr_pairs;
}

sub crispr_oligo_rs {
    my $schema = shift;
    my $crispr_id = shift;

    my $crispr_rs = $schema->resultset('Crispr')->search(
        {
            'id' => $crispr_id,
        },
    );

    return $crispr_rs;
}

=head junk

sub crisprs_for_region {
    my $schema = shift;
    my $params = shift;

    # Chromosome number is looked up in the chromosomes table to get the chromosome_id
    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $crisprs_rs = $schema->resultset('CrisprLocus')->search(
        {
            'assembly_id' => $params->{assembly_id},
            'chr_id'      => $params->{chromosome_id},
            # need all the crisprs starting with values >= start_coord
            # and whose start values are <= end_coord
            'chr_start'   => { -between => [
                $params->{start_coord},
                $params->{end_coord},
                ],
            },
        },
    );

    return $crisprs_rs;
}
=cut

=head get_crispr_pair_EnsEmbl_region

We calculate crisprs left and right on the same strand as the gene.
Thus we need the gene's strand to get the correct sequence region.
We don't use the crispr strand information.

[SF1] >100bp [Left_Crispr] --- [Right_Crispr] > 100bp [SR1]

SF and SR with respect to the sense of the gene (not the sense of EnsEmbl)
=cut

sub get_crispr_pair_EnsEmbl_region {
    my $params = shift;
    my $crispr_oligos = shift;

    my $design_r = $params->{'schema'}->resultset('Design')->find($params->{'design_id'});
    my $design_info = LIMS2::Model::Util::DesignInfo->new( design => $design_r );
    my $design_oligos = $design_info->oligos;
    my $repeat_mask = $params->{'repeat_mask'};

    my $chr_strand = $design_info->chr_strand eq '1' ? 'plus' : 'minus';

    my $slice_region;
    my $seq;
    my $crispr_length = length($crispr_oligos->{'left_crispr'}->{'seq'});
    # dead field width is the number of bases in which primers must not be found.
    # This is because sequencing oligos needs some run-in to the region of interest.
    # So, we need a region that covers from the 3' end of the crispr back to (len_crispr + dead_field + live_field)
    # 5' (live_field + dead_field + len_crispr)
    my $dead_field_width = 100;
    my $search_field_width = 200;

    my $start_coord = $crispr_oligos->{'left_crispr'}->{'chr_start'};
    my $region_start_coord = $start_coord - ($dead_field_width + $search_field_width);
    my $end_coord = $crispr_oligos->{'right_crispr'}->{'chr_end'};
    my $region_end_coord = $end_coord + ($dead_field_width + $search_field_width );

    my $slice_adaptor = $registry->get_adaptor($params->{'species'}, 'Core', 'Slice');
    if ( $chr_strand eq 'plus' ) {
        $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $crispr_oligos->{'left_crispr'}->{'chr_name'},
            $region_start_coord,
            $region_end_coord,
            1,

        );
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 0,
            });
    }
    elsif ( $chr_strand eq 'minus' ) {
        $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $crispr_oligos->{'left_crispr'}->{'chr_name'},
            $region_start_coord,
            $region_end_coord,
            -1,
        );
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 1,
            });
    }

    my $target_sequence_length = ($end_coord - $start_coord) + 2 * $dead_field_width;
    # target sequence is <start, length> and in this case indicates the region we want to sequence

    my $target_sequence_string =  $search_field_width . ',' . $target_sequence_length;

    my $chr_seq_start = $slice_region->start;
    my $chr_seq_end = $slice_region->end;
    return ($seq, $target_sequence_string, $target_sequence_length, $chr_strand,
            $chr_seq_start, $chr_seq_end);
}

sub get_single_crispr_EnsEmbl_region {
    my $params = shift;
    my $crispr_oligos = shift;

    my $design_r = $params->{'schema'}->resultset('Design')->find($params->{'design_id'});
    my $design_info = LIMS2::Model::Util::DesignInfo->new( design => $design_r );
    my $design_oligos = $design_info->oligos;
    my $repeat_mask = $params->{'repeat_mask'};

    my $chr_strand = $design_info->chr_strand eq '1' ? 'plus' : 'minus';

    my $slice_region;
    my $seq;
    my $crispr_length = length($crispr_oligos->{'left_crispr'}->{'seq'});
    # dead field width is the number of bases in which primers must not be found.
    # This is because sequencing oligos needs some run-in to the region of interest.
    # So, we need a region that covers from the 3' end of the crispr back to (len_crispr + dead_field + live_field)
    # 5' (live_field + dead_field + len_crispr)
    my $dead_field_width = 100;
    my $search_field_width = 200;

    my $start_coord = $crispr_oligos->{'left_crispr'}->{'chr_start'};
    my $region_start_coord = $start_coord - ($dead_field_width + $search_field_width);
    my $end_coord = $crispr_oligos->{'left_crispr'}->{'chr_end'}; # this is a singleton crispr
    my $region_end_coord = $end_coord + ($dead_field_width + $search_field_width );

    my $slice_adaptor = $registry->get_adaptor($params->{'species'}, 'Core', 'Slice');
    if ( $chr_strand eq 'plus' ) {
        $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $crispr_oligos->{'left_crispr'}->{'chr_name'},
            $region_start_coord,
            $region_end_coord,
            1,

        );
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 0,
            });
    }
    elsif ( $chr_strand eq 'minus' ) {
        $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $crispr_oligos->{'left_crispr'}->{'chr_name'},
            $region_start_coord,
            $region_end_coord,
            -1,
        );
        $seq = get_repeat_masked_sequence( {
                slice_region => $slice_region,
                repeat_mask => $repeat_mask,
                revcom  => 1,
            });
    }

    my $target_sequence_length = ($end_coord - $start_coord) + 2 * $dead_field_width;
    # target sequence is <start, length> and in this case indicates the region we want to sequence

    my $target_sequence_string =  $search_field_width . ',' . $target_sequence_length;

    my $chr_seq_start = $slice_region->start;
    my $chr_seq_end = $slice_region->end;
    return ($seq, $target_sequence_string, $target_sequence_length, $chr_strand,
            $chr_seq_start, $chr_seq_end)  ;
}


=head get_crispr_EnsEmbl_region
Debugging and development only

An approach for a single crispr sequencing but probably should use the paired crispr approach
in get_crispr_pair_EnsEmbl_region
=cut

sub get_crispr_EnsEmbl_region {
    my $crispr_oligos = shift;
    my $side = shift;
    my $species = shift;


    my $chr_strand = $crispr_oligos->{$side}->{'chr_strand'} eq '1' ? 'plus' : 'minus';
    my $slice_region;
    my $seq;
    my $crispr_length = length($crispr_oligos->{$side}->{'seq'});
    # dead field width is the number of bases in which primers must not be found.
    # This is because sequencing oligos nees some run-in to the region of interest.
    # So, we need a region that covers from the 3' end of the crispr back to (len_crispr + dead_field + live_field)
    # 5' (live_field + dead_field + len_crispr)
    my $dead_field_width = 100;
    my $live_field_width = 200;

    my $slice_adaptor = $registry->get_adaptor($species, 'Core', 'Slice');
    if ( $chr_strand eq 'plus' ) {
        $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $crispr_oligos->{$side}->{'chr_name'},
            $crispr_oligos->{$side}->{'chr_start'} - $dead_field_width - $live_field_width,
            $crispr_oligos->{$side}->{'chr_end'},
            $crispr_oligos->{$side}->{'chr_strand'},

        );
        $seq = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_region->seq, -verbose => -1 );
    }
    elsif ( $chr_strand eq 'minus' ) {
        $slice_region = $slice_adaptor->fetch_by_region(
            'chromosome',
            $crispr_oligos->{$side}->{'chr_name'},
            $crispr_oligos->{$side}->{'chr_start'} - $dead_field_width - $live_field_width,
            $crispr_oligos->{$side}->{'chr_end'},
            $crispr_oligos->{$side}->{'chr_strand'},
        );
        # $seq = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_region->seq, -verbose => -1 )->revcom;
        $seq = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_region->seq, -verbose => -1 );
    }

    my $target_sequence_length = $seq->length - ($dead_field_width + $crispr_length);
    # target sequence is <start, length> and in this case indicates the region we want to sequence
    my $target_sequence_string = '1' . ',' . $target_sequence_length;

    my $chr_seq_start = $slice_region->start;
    my $chr_seq_end = $slice_region->end;
    return ($seq, $target_sequence_string, $target_sequence_length, $chr_seq_start, $chr_seq_end) ;
}


sub get_repeat_masked_sequence {
    my $params = shift;

    my $slice_region = $params->{'slice_region'};
    my $repeat_mask = $params->{'repeat_mask'};
    my $revcom = $params->{'revcom'};
    my $seq;
    if ( $repeat_mask->[0] eq 'NONE' ) {
        DEBUG('No repeat masking selected');
        $seq = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_region->seq, -verbose => -1 );
    }
    else {
        DEBUG('Repeat masking selected');
        $seq = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_region->get_repeatmasked_seq($repeat_mask)->seq, -verbose => -1 );
    }
    if ( $revcom ) {
        $seq = $seq->revcom;
    }
    return $seq;
}

# Retrieve crispr primer sets

=head retrieve_crispr_primers
Given
    params => {
        'schema'         => LIMS2::Schema,
        'crispr_pair_id' => value,
        'crispr_id'      => value,
    }
Returns a hashref keyed on primer labels that contains assembly and coordinate information

=cut

sub retrieve_crispr_primers {
    my $schema = shift;
    my $params = shift;

    my $crispr_pair_id  = $params->{'crispr_pair_id'};
    my $single_crispr_id = $params->{'crispr_id'};

    my $crispr_col_label;
    my $crispr_id_value;
    if ($single_crispr_id ) {
       $crispr_col_label = 'crispr_id';
       $crispr_id_value = $single_crispr_id;
    }
    else {
        $crispr_col_label = 'crispr_pair_id';
        $crispr_id_value = $crispr_pair_id;
    }

    my %crispr_primers_hash;

    my $crispr_primers_rs = $schema->resultset('CrisprPrimer')->search({
        $crispr_col_label => $crispr_id_value,
    });
    if ($crispr_primers_rs) {
        my $count = 0;
        while ( my $crispr_primers_row = $crispr_primers_rs->next ) {
#FIXME: Owing to the primer_name column also being the name of the belongs to relationship...
            $crispr_primers_hash{$crispr_id_value}->{$crispr_primers_row->primer_name->primer_name} = {
                'primer_seq' => $crispr_primers_row->primer_seq,
                'chr_start' => $crispr_primers_row->crispr_primer_loci->single->chr_start,
                'chr_end'  => $crispr_primers_row->crispr_primer_loci->single->chr_end,
                'chr_strand' => $crispr_primers_row->crispr_primer_loci->single->chr_strand,
                'chr_id' => $crispr_primers_row->crispr_primer_loci->single->chr_id,
                'assembly_id' => $crispr_primers_row->crispr_primer_loci->single->assembly_id,
            };
        }
    }
    # Now the genotyping primers
    my $g_primer_hash = get_db_genotyping_primers_as_hash($schema, $params );
    while ( my ($label, $val) = each %$g_primer_hash ) {
        $crispr_primers_hash{$crispr_id_value}->{$label} = $val;
    }

    return \%crispr_primers_hash;
}

# Return the maximum distance between GF and GR
#


sub get_db_genotyping_primers_as_hash {
    my $schema = shift;
    my $params = shift;

    my $genotyping_primer_rs = $schema->resultset('GenotypingPrimer')->search({
            'design_id' => $params->{'design_id'},
        },
        {
            'prefetch'   => ['genotyping_primer_loci'],
        },
    );
    my %g_primer_hash;
    # The genotyping primer table has no unique constraint and may have multiple redundant entries
    # So the %g_primer_hash gets rid of the redundancy
    while ( my $g_primer = $genotyping_primer_rs->next ) {
        $g_primer_hash{ $g_primer->genotyping_primer_type_id } = {
            'primer_seq' => $g_primer->seq,
            'chr_start' => $g_primer->genotyping_primer_loci->first->chr_start,
            'chr_end' => $g_primer->genotyping_primer_loci->first->chr_end,
            'chr_id' => $g_primer->genotyping_primer_loci->first->chr_id,
            'chr_name' => $g_primer->genotyping_primer_loci->first->chr->name,
            'chr_strand' => $g_primer->genotyping_primer_loci->first->chr_strand,
            'assembly_id' => $g_primer->genotyping_primer_loci->single->assembly_id,

        }
    }

    return \%g_primer_hash;
}


=head get_genotyping_extent

Given

Returns
hashref:
    start_coord
    end_coord
    chr_name
    assembly
=cut

sub get_genotyping_primer_extent {
    my $schema = shift;
    my $params = shift;
    my $species = shift;

    my $g_primer_hash = get_db_genotyping_primers_as_hash($schema, $params );

    my %extent_hash;

    # Simply compare all the start and end positions (chr_start, chr_end) and take the min of chr_start and the max of chr_end

    $extent_hash{'chr_start'} = $g_primer_hash->{'GF1'}->{'chr_start'};
    $extent_hash{'chr_end'} = $g_primer_hash->{'GF1'}->{'chr_end'};
    while ( my ($primer, $vals) = each %$g_primer_hash ) {
        $extent_hash{'chr_start'} = $vals->{'chr_start'} if $extent_hash{'chr_start'} > $vals->{'chr_start'};
        $extent_hash{'chr_end'} = $vals->{'chr_end'} if $extent_hash{'chr_end'} < $vals->{'chr_start'};
    }
    $extent_hash{'chr_name'} = $g_primer_hash->{'GF1'}->{'chr_name'};
    $extent_hash{'assembly'} = get_species_default_assembly( $schema, $species);

    return \%extent_hash;
}

sub get_species_default_assembly {
    my $schema = shift;
    my $species = shift;

    my $assembly_r = $schema->resultset('SpeciesDefaultAssembly')->find( { species_id => $species } );

    return $assembly_r->assembly_id || undef;

}

1;
