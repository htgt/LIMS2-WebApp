package LIMS2::Model::Util::OligoSelection;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::OligoSelection::VERSION = '0.478';
}
## use critic


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
        pick_crispr_PCR_primers
        retrieve_crispr_primers
        retrieve_crispr_data_for_id
        get_db_genotyping_primers_as_hash
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


=head pick_PCR_primers_for_crisprs
    given location of crispr primers as an input,
    search for primers to generate a PCR product covering the region of the crispr primers
    This is modeled on the genotyping primers and therefore includes a genomic check
=cut


sub pick_crispr_PCR_primers {
    my $model = shift;
    my $params = shift;

    $params->{'search_field_width'} = $ENV{'LIMS2_PCR_SEARCH_FIELD'} // 500;
    $params->{'dead_field_width'} = $ENV{'LIMS2_PCR_DEAD_FIELD'} // 100;

    # chr_strand for the gene is required because the crispr primers are named accordingly SF1, SR1
    my ($primer_data, $primer_passes, $chr_seq_start);
    PCR_TRIALS: foreach my $step ( 1..4 ) {
        INFO ('PCR attempt No. ' . $step );
        ($primer_data, $primer_passes, $chr_seq_start) = crispr_PCR_calculate($model, $params );
        if ($primer_data->{'error_flag'} eq 'pass') {
            INFO ('PCR Primer3 attempt No. ' . $step . ' succeeded');
            if ($primer_passes->{'genomic_error_flag'} eq 'pass' ) {
                INFO ('PCR genomic check returned ' . $primer_passes->{'pair_count'} . ' unique primer pairs');
                last PCR_TRIALS;
            }
            else {
                INFO ( 'PCR genomic checked failed: found non-unique genomic alignmemts');
            }
        }
        # increment the fields for searching next time round.
        $params->{'dead_field_width'} += $params->{'search_field_width'};
        $params->{'search_field_width'} += 1000;
    }

    return ($primer_data, $primer_passes, $chr_seq_start);
}

sub crispr_PCR_calculate {
    my $model = shift;
    my $params = shift;

    my $schema = $model->schema;
    my $well_id = $params->{'well_id'};
    my $crispr_primers = $params->{'crispr_primers'};
    my $species = $params->{'species'};
    my $repeat_mask = $params->{'repeat_mask'};
    # Return the design oligos as well so that we can report them to provide context later on
    my ($region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_seq_start )
        = get_crispr_PCR_EnsEmbl_region($model, {
                crispr_primers => $crispr_primers,
                species => $species,
                repeat_mask => $repeat_mask,
                dead_field_width => $params->{'dead_field_width'},
                search_field_width => $params->{'search_field_width'},
            } );
    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_PCR_CRISPR_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length
            + $params->{'search_field_width'} ),
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
        $primer_data->{'error_flag'} = 'pass';
        $primer_passes = pcr_genomic_check( $well_id, $species, $primer_data );
        $primer_passes->{'genomic_error_flag'} = $primer_passes->{'pair_count'} > 0 ? 'pass' : 'fail';
    }
    else {
        WARN ( "Failed to generate pcr primer pairs for $well_id" );
        WARN ( 'Primer3 reported: ');
        WARN ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        WARN ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
        $primer_data->{'error_flag'} = 'fail';
    }
    return $primer_data, $primer_passes, $chr_seq_start;
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
    my $model = shift;
    my $params = shift;

    $params->{'start_oligo_field_width'} = $ENV{'LIMS2_GENOTYPING_START_FIELD'} // 1000;
    $params->{'end_oligo_field_width'} = $ENV{'LIMS2_GENOTYPING_END_FIELD'} // 1000;
    INFO ('start_oligo_field_width = ' . $params->{'start_oligo_field_width'});
    INFO ('end_oligo_field_width = ' . $params->{'end_oligo_field_width'});


    # chr_strand for the gene is required because the crispr primers are named accordingly SF1, SR1
    my ($primer_data, $primer_passes, $chr_strand, $design_oligos, $chr_seq_start, $chr_name);
    GENO_TRIALS: foreach my $step ( 1..($ENV{'LIMS2_GENOTYPING_ITERATION_MAX'}//4) ) {
        INFO ('Genotyping attempt No. ' . $step );
        ($primer_data, $primer_passes, $chr_strand, $design_oligos, $chr_seq_start, $chr_name)
            = genotyping_calculate( $model, $params );
        if ($primer_data->{'error_flag'} eq 'pass') {
            INFO ('Genotyping Primer3 attempt No. ' . $step . ' succeeded');
            if ($primer_passes->{'genomic_error_flag'} eq 'pass' ) {
                INFO ('Genotyping genomic check returned ' . $primer_passes->{'pair_count'} . ' unique primer pairs');
                last GENO_TRIALS;
            }
            else {
                INFO ( 'Genotyping genomic checked failed: found non-unique genomic alignmemts');
            }
        }
        # increment the fields for searching next time round.
        # for genotyping we just go in steps of 1Kb - there is no dead field defined for genotyping
        INFO ('Genotyping chunk size set to: ' . ($ENV{'LIMS2_GENOTYPING_CHUNK_SIZE'} // 1000));
        $params->{'start_oligo_field_width'} += $ENV{'LIMS2_GENOTYPING_CHUNK_SIZE'} // 1000;
        $params->{'end_oligo_field_width'} += $ENV{'LIMS2_GENOTYPING_CHUNK_SIZE'} // 1000;
    }
    return ($primer_data, $primer_passes, $chr_strand, $design_oligos, $chr_seq_start, $chr_name);
}

sub genotyping_calculate {
    my $model = shift;
    my $params = shift;

    my $schema = $model->schema;
    my $design_id = $params->{'design_id'};
    my $well_id = $params->{'well_id'};
    my $species = $params->{'species'};
    my $repeat_mask = $params->{'repeat_mask'};

    # Return the design oligos as well so that we can report them to provide context later on
    my ($region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_strand, $design_oligos, $chr_seq_start, $chr_name)
        = get_genotyping_EnsEmbl_region( $model, {
                design_id => $design_id,
                repeat_mask => $repeat_mask,
                start_oligo_field_width => $params->{'start_oligo_field_width'},
                end_oligo_field_width => $params->{'end_oligo_field_width'},
            } );

    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_GIBSON_GENOTYPING_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-'
            . ($target_sequence_length + $params->{'start_oligo_field_width'} - ($ENV{'LIMS2_PRIMER_OFFSET'}//500)), # ?? was static 500
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
        $primer_data->{'error_flag'} = 'pass';
        $primer_passes = genomic_check( $design_id, $well_id, $species, $primer_data, $chr_strand );
        $primer_passes->{'genomic_error_flag'} = $primer_passes->{'pair_count'} > 0 ? 'pass' : 'fail';
    }
    else {
        WARN ( "Failed to generate genotyping primer pairs for $design_id" );
        WARN ( 'Primer3 reported: ');
        WARN ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        WARN ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
        $primer_data->{'error_flag'} = 'fail';
   }
   return ($primer_data, $primer_passes, $chr_strand, $design_oligos, $chr_seq_start, $chr_name);
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
            $primer_data->{'pair_count'} --;
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

sub list_primers {
    my $primer_data = shift;
    use Data::Dumper;
    return if ! $ENV{'LIMS2_DUMP_PRIMERS'};

    print Dumper( $primer_data );

    return;
}

sub primer_driver {
    my %params;

    $params{'schema'} = shift->schema;
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
    my $model = shift;
    my $params = shift;

    my $gibson_design_oligos_rs = gibson_design_oligos_rs( $model->schema, $params->{'design_id'} );
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
    my $model = shift;
    my $params = shift;

    my $design_r = $model->schema->resultset('Design')->find($params->{'design_id'});
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
    my $model = shift;
    my $params = shift;

    my $schema = $model->schema;
    my $crispr_primers = $params->{'crispr_primers'};
    my $species = $params->{'species'};
    my $repeat_mask = $params->{'repeat_mask'};

    my $slice_region;

    # Here we want a slice from the beginning of (start(left_0) - ($dead_width + $search_field))
    # to the end(right_0) + ($dead_width + $search_field)
    my $dead_field_width = $params->{'dead_field_width'} // 100;
    my $search_field_width = $params->{'search_field_width'} // 500;

    INFO ('pcr primer dead_field_width: ' . $dead_field_width );
    INFO ('pcr primer search_field_width: ' . $search_field_width);

    my $chr_strand = $crispr_primers->{'strand'}; # That is the gene strand

    my $slice_adaptor = $model->ensembl_slice_adaptor($species);
    my $seq;

    my $start_target = $crispr_primers->{'crispr_primers'}->{'left'}->{'left_0'}->{'location'}->start
        + $crispr_primers->{'crispr_seq'}->{'chr_region_start'} ;
    my $end_target = $crispr_primers->{'crispr_primers'}->{'right'}->{'right_0'}->{'location'}->end
        + $crispr_primers->{'crispr_seq'}->{'chr_region_start'};
INFO("PCR start target: $start_target");
INFO("PCR end target: $end_target");
    my $start_coord =  $start_target - ($dead_field_width + $search_field_width);
    my $end_coord =  $end_target + ($dead_field_width + $search_field_width);
    $slice_region = $slice_adaptor->fetch_by_region(
        'chromosome',
        $crispr_primers->{'crispr_seq'}->{'left_crispr'}->{'chr_name'},
        $start_coord,
        $end_coord,
        $chr_strand eq 'plus' ? '1' : '-1' ,
    );
    # TODO check the code below with David
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
    my $model = shift;
    my $params = shift;

    my $design_r = $model->schema->resultset('Design')->find($params->{'design_id'});
    my $design_info = LIMS2::Model::Util::DesignInfo->new( design => $design_r );
    my $design_oligos = $design_info->oligos;
    my $repeat_mask = $params->{'repeat_mask'};

    my $chr_strand = $design_info->chr_strand eq '1' ? 'plus' : 'minus';
    my $slice_region;
    my $seq;

    my $start_oligo_field_width = $params->{'start_oligo_field_width'}; #1000;
    my $end_oligo_field_width = $params->{'end_oligo_field_width'}; #1000;
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

    return ($seq,
            $target_sequence_string,
            $target_sequence_length,
            $chr_strand, $design_oligos,
            $chr_region_start,
            $design_info->chr_name
        );

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
    my $model = shift;
    my $params = shift;

    my $crispr_oligos = oligos_for_crispr_pair( $model->schema, $params->{'crispr_pair_id'} );
    $params->{crispr_oligos} = $crispr_oligos;
    $params->{'search_field_width'} = $ENV{'LIMS2_SEQ_SEARCH_FIELD'} // 200;
    $params->{'dead_field_width'} = $ENV{'LIMS2_SEQ_DEAD_FIELD'} // 100;
    # chr_strand for the gene is required because the crispr primers are named accordingly SF1, SR1
    my ($primer_data, $chr_strand, $chr_seq_start);
    TRIALS: foreach my $step ( 1..4 ) {
        INFO ('Attempt No. ' . $step );
        ($primer_data, $chr_strand, $chr_seq_start) = crispr_primer_calculate( $model, $params, $crispr_oligos );
        if ($primer_data->{'error_flag'} eq 'pass') {
            INFO ('Attempt No. ' . $step . ' succeeded');
            last TRIALS;
        }
        # increment the fields for searching next time round.
        $params->{'dead_field_width'} += $params->{'search_field_width'};
        $params->{'search_field_width'} += 500;
    }

    return ($crispr_oligos, $primer_data, $chr_strand, $chr_seq_start);
}

sub crispr_primer_calculate {
    my $model = shift;
    my $params = shift;
    my $crispr_oligos = shift;

    my $repeat_mask = $params->{'repeat_mask'};

    my ( $region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_strand,
        $chr_seq_start, $chr_seq_end)
        = get_crispr_pair_EnsEmbl_region($model, $params, $crispr_oligos, $repeat_mask);

        # FIXME:do we need this? we now return as a $chr_seq_start separate list item
    $crispr_oligos->{'chr_region_start'} = $chr_seq_start;

# for the default search_field_width of 200, adding a constant 300 gives range up to 500 for compatibility with previous versions
# of this code that had a fixed sequencing search field width and set the product size range to
# ($target_sequence_length + 500). These ranges have a significant impact on the primers generated.

    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_CRISPR_SEQUENCING_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length
            + $params->{'search_field_width' } + 300),
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
        list_primers( $primer_data );
        $primer_data->{'error_flag'} = 'pass';
    }
    else {
        WARN ( 'Failed to generate sequencing primers for ' . $params->{'crispr_pair_id'} );
        WARN ( 'Primer3 reported: ');
        WARN ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        WARN ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
        $primer_data->{'primer3_explain_left'} = $primer3_explain->{'PRIMER_LEFT_EXPLAIN'};
        $primer_data->{'primer3_explain_right'} = $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'};
        $primer_data->{'error_flag'} = 'fail';
    }
    return $primer_data, $chr_strand, $chr_seq_start;
}

sub pick_single_crispr_primers {
    my $model = shift;
    my $params = shift;

    my $crispr_oligos = oligo_for_single_crispr( $model->schema, $params->{'crispr_id'} );
    $params->{'crispr_oligos'} = $crispr_oligos;
    $params->{'search_field_width'} = $ENV{'LIMS2_SEQ_SEARCH_FIELD'} // 200;
    $params->{'dead_field_width'} = $ENV{'LIMS2_SEQ_DEAD_FIELD'} // 100;
    # chr_strand for the gene is required because the crispr primers are named accordingly SF1, SR1
    my ($primer_data, $chr_strand, $chr_seq_start);
    TRIALS: foreach my $step ( 1..4 ) {
        INFO ('Attempt No. ' . $step );
        ($primer_data, $chr_strand, $chr_seq_start) = single_crispr_primer_calculate( $model, $params, $crispr_oligos );
        if ($primer_data->{'error_flag'} eq 'pass') {
            INFO ('Attempt No. ' . $step . ' succeeded');
            last TRIALS;
        }
        # increment the fields for searching next time round.
        $params->{'dead_field_width'} += $params->{'search_field_width'};
        $params->{'search_field_width'} += 500;
    }

    return ($crispr_oligos, $primer_data, $chr_strand, $chr_seq_start);

}

sub single_crispr_primer_calculate {
    my $model = shift;
    my $params = shift;
    my $crispr_oligos = shift;

    my $repeat_mask = $params->{'repeat_mask'};

    # chr_strand for the gene is required because the crispr primers are named accordingly SF1, SR1
    my ( $region_bio_seq, $target_sequence_mask, $target_sequence_length, $chr_strand,
        $chr_seq_start, $chr_seq_end)
        = get_single_crispr_EnsEmbl_region($model, $params, $crispr_oligos, $repeat_mask );

    $crispr_oligos->{'chr_region_start'} = $chr_seq_start;

    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_CRISPR_SEQUENCING_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length
            + $params->{'search_field_width' } + 300 ),
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
        list_primers( $primer_data );
        $primer_data->{'error_flag'} = 'pass';
    }
    else {
        WARN ( 'Failed to generate sequencing primers for ' . $params->{'crispr_id'} );
        WARN ( 'Primer3 reported: ');
        WARN ( $primer3_explain->{'PRIMER_LEFT_EXPLAIN'} );
        WARN ( $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'} );
        $primer_data->{'primer3_explain_left'} = $primer3_explain->{'PRIMER_LEFT_EXPLAIN'};
        $primer_data->{'primer3_explain_right'} = $primer3_explain->{'PRIMER_RIGHT_EXPLAIN'};
        $primer_data->{'error_flag'} = 'fail';    }

    return ($primer_data, $chr_strand, $chr_seq_start);
}

# Use oligo_for_single_crispr to generate hash for each of the crisprs in the group
# return these hashes in an arrayref
sub oligos_for_crispr_group{
    my ($schema, $group_id)  = @_;
    my @oligos;

    my $group = $schema->resultset('CrisprGroup')->find({ id => $group_id });

    foreach my $crispr_group_crispr ($group->crispr_group_crisprs){
        my $crispr_oligo_hash = oligo_for_single_crispr($schema, $crispr_group_crispr->crispr_id);
        push @oligos, $crispr_oligo_hash->{'left_crispr'};
    }
    return \@oligos;
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
    $crispr_pairs{'left_crispr'}->{'pam_right'} = $crispr_pair->left_crispr_locus->crispr->pam_right;

    $crispr_pairs{'right_crispr'}->{'id'} = $crispr_pair->right_crispr_locus->crispr_id;
    $crispr_pairs{'right_crispr'}->{'chr_start'} = $crispr_pair->right_crispr_locus->chr_start;
    $crispr_pairs{'right_crispr'}->{'chr_end'} = $crispr_pair->right_crispr_locus->chr_end;
    $crispr_pairs{'right_crispr'}->{'chr_strand'} = $crispr_pair->right_crispr_locus->chr_strand;
    $crispr_pairs{'right_crispr'}->{'chr_id'} = $crispr_pair->right_crispr_locus->chr_id;
    $crispr_pairs{'right_crispr'}->{'chr_name'} = $crispr_pair->right_crispr_locus->chr->name;
    $crispr_pairs{'right_crispr'}->{'seq'} = $crispr_pair->right_crispr_locus->crispr->seq;
    $crispr_pairs{'right_crispr'}->{'pam_right'} = $crispr_pair->right_crispr_locus->crispr->pam_right;

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
    my $assembly_id = shift;

    my $crispr_rs = crispr_oligo_rs( $schema, $crispr_id );
    my $crispr = $crispr_rs->first;

    # If no assembly has been specified use species default
    unless($assembly_id){
        $assembly_id = $crispr->species->default_assembly->assembly_id;
    }

    my %crispr_pairs;
    $crispr_pairs{'left_crispr'}->{'id'} = $crispr->id;
    my @loci = $crispr->loci->search({ assembly_id => $assembly_id });

    my $locus_count = scalar @loci;
    if ($locus_count > 1 ) {
        INFO ('Found multiple loci for ' . $crispr_id);
    }
    elsif($locus_count == 0){
        INFO ("No locus on assembly $assembly_id for crispr ".$crispr_id);
        return {};
    }
    my $locus = $loci[0];

    $crispr_pairs{'left_crispr'}->{'chr_start'} = $locus->chr_start;
    $crispr_pairs{'left_crispr'}->{'chr_end'} = $locus->chr_end;
    $crispr_pairs{'left_crispr'}->{'chr_strand'} = $locus->chr_strand;
    $crispr_pairs{'left_crispr'}->{'chr_id'} = $locus->chr_id;
    $crispr_pairs{'left_crispr'}->{'chr_name'} = $locus->chr->name;
    $crispr_pairs{'left_crispr'}->{'seq'} = $crispr->seq;
    $crispr_pairs{'left_crispr'}->{'pam_right'} = $crispr->pam_right;

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

=head get_crispr_pair_EnsEmbl_region

We calculate crisprs left and right on the same strand as the gene.
Thus we need the gene's strand to get the correct sequence region.
We don't use the crispr strand information.

[SF1] >100bp [Left_Crispr] --- [Right_Crispr] > 100bp [SR1]

SF and SR with respect to the sense of the gene (not the sense of EnsEmbl)
=cut

sub get_crispr_pair_EnsEmbl_region {
    my $model = shift;
    my $params = shift;
    my $crispr_oligos = shift;

    my $design_r = $model->schema->resultset('Design')->find($params->{'design_id'});
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
    my $dead_field_width = $params->{'dead_field_width'};
    my $search_field_width = $params->{'search_field_width'};
    INFO ('sequencing primer dead_field_width: ' . $dead_field_width );
    INFO ('sequencing primer search_field_width: ' . $search_field_width);


    my $start_coord = $crispr_oligos->{'left_crispr'}->{'chr_start'};
    my $region_start_coord = $start_coord - ($dead_field_width + $search_field_width);
    my $end_coord = $crispr_oligos->{'right_crispr'}->{'chr_end'};
    my $region_end_coord = $end_coord + ($dead_field_width + $search_field_width );

    my $slice_adaptor = $model->ensembl_slice_adaptor($params->{'species'});
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
    my $model = shift;
    my $params = shift;
    my $crispr_oligos = shift;

    my $design_r = $model->schema->resultset('Design')->find($params->{'design_id'});
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

    my $slice_adaptor = $model->ensembl_slice_adaptor($params->{'species'});
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
        'crispr_type'    => crispr_pair_id or crispr_id,
        'crispr_type_id'      => value of crispr_type
    }
Returns a hashref keyed on primer labels that contains assembly and coordinate information

=cut

sub retrieve_crispr_primers {
    my $schema = shift;
    my $params = shift;

    my $crispr_id_ref  = $params->{'crispr_id_ref'};
    my $crispr_id = $params->{'crispr_id'};

    my %crispr_primers_hash;

    # I am assuming we do not want to return rejected primers af11 2015-02-05
    my $crispr_primers_rs = $schema->resultset('CrisprPrimer')->search({
        $crispr_id_ref => $crispr_id,
        is_rejected => [0,undef],
    });

    my $crispr_type_string;

    if ( $crispr_id_ref eq 'crispr_id' ) {
       $crispr_type_string = 'crispr_single';
    }
    elsif ( $crispr_id_ref eq 'crispr_pair_id' ) {
       $crispr_type_string = 'crispr_pair';
    }
    elsif ( $crispr_id_ref eq 'crispr_group_id'){
        $crispr_type_string = 'crispr_group';
    }

    if ($crispr_primers_rs) {
        my $count = 0;
        while ( my $crispr_primers_row = $crispr_primers_rs->next ) {
#FIXME: Owing to the primer_name column also being the name of the belongs to relationship...
            my $primer_loci = $crispr_primers_row->crispr_primer_loci->find({ assembly_id => $params->{'assembly_id'} });
            $crispr_primers_hash{$crispr_type_string}->{$crispr_id}->{$crispr_primers_row->primer_name->primer_name} = {
                'primer_seq' => $crispr_primers_row->primer_seq,
                'chr_start' => $primer_loci->chr_start,
                'chr_end'  => $primer_loci->chr_end,
                'chr_strand' => $primer_loci->chr_strand,
                'chr_id' => $primer_loci->chr_id,
                'assembly_id' => $primer_loci->assembly_id,
            };
        }
    }
    # Now the genotyping primers
    my $g_primer_hash = get_db_genotyping_primers_as_hash($schema, $params );
    # If the hash is empty - there were no genotyping primers for this design that we can use
    if ( %$g_primer_hash ) {
        while ( my ($label, $val) = each %$g_primer_hash ) {
            $crispr_primers_hash{$crispr_type_string}->{$crispr_id}->{$label} = $val;
        }
    }

    return \%crispr_primers_hash;
}

# Return the maximum distance between GF and GR
#


sub get_db_genotyping_primers_as_hash {
    my $schema = shift;
    my $params = shift;

    # Skip this id we have no design ID
    return {} unless $params->{'design_id'};

    my $genotyping_primer_rs = $schema->resultset('GenotypingPrimer')->search({
            'design_id' => $params->{'design_id'},
        },
        {
            'prefetch'   => ['genotyping_primer_loci'],
        },
    );
    if ( $genotyping_primer_rs->count == 0 ) {
         LIMS2::Exception->throw( 'No primer data found for design: ' . $params->{'design_id'});
    }

    my %g_primer_hash;
    # The genotyping primer table has no unique constraint and may have multiple redundant entries
    # So the %g_primer_hash gets rid of the redundancy
    # Old Mouse GF/GR primers have no locus information
    #

    while ( my $g_primer = $genotyping_primer_rs->next ) {
        if ( $g_primer->genotyping_primer_type_id =~ m/G[FR][12]/ ) {
            last if $g_primer->genotyping_primer_loci->count == 0;
            my $g_locus = $g_primer->genotyping_primer_loci->find({ 'assembly_id' => $params->{'assembly_id'} });
            $g_primer_hash{ $g_primer->genotyping_primer_type_id } = {
                'primer_seq' => $g_primer->seq,
                'chr_start' => $g_locus->chr_start,
                'chr_end' => $g_locus->chr_end,
                'chr_id' => $g_locus->chr_id,
                'chr_name' => $g_locus->chr->name,
                'chr_strand' => $g_locus->chr_strand,
                'assembly_id' => $g_locus->assembly_id,
            }
        }
    }

    return \%g_primer_hash;
}

sub retrieve_crispr_data_for_id {
    my $schema = shift;
    my $params = shift;

    my $crispr_id_ref  = $params->{'crispr_id_ref'};
    my $crispr_id = $params->{'crispr_id'};

    my %crispr_data_hash;

    if ( $crispr_id_ref eq 'crispr_pair_id' ) {
        $crispr_data_hash{'crispr_pair'}->{$crispr_id} = oligos_for_crispr_pair( $schema, $crispr_id );
    }
    elsif ($crispr_id_ref eq 'crispr_id' ) {
        $crispr_data_hash{'crispr_single'}->{$crispr_id} = oligo_for_single_crispr( $schema, $crispr_id );
    }
    elsif ($crispr_id_ref eq 'crispr_group_id'){
        # For each crispr group we get an array ref of single crispr oligo details
        $crispr_data_hash{'crispr_group'}->{$crispr_id} = oligos_for_crispr_group( $schema, $crispr_id );
    }
    else {
        ERROR ('crispr identifier: ' . $crispr_id . ' was not found in the database');
        # signal an error
        die;
    }

    return \%crispr_data_hash;
}

1;
