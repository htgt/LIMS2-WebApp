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

use Bio::SeqIO;
use Path::Class;

sub pick_genotyping_primers {
    my $schema = shift;
    my $design_id = shift;

    my %failed_primer_regions;
    my ($region_bio_seq, $target_sequence_mask, $target_sequence_length)
        = get_EnsEmbl_region( { schema => $schema, design_id => $design_id } );

    my $p3 = DesignCreate::Util::Primer3->new_with_config(
        configfile => $ENV{ 'LIMS2_PRIMER3_GIBSON_GENOTYPING_PRIMER_CONFIG' },
        primer_product_size_range => $target_sequence_length . '-' . ($target_sequence_length + 500),
    );

    my $dir_out = dir( $ENV{ 'LIMS2_PRIMER_SELECTION_DIR' } );
    my $logfile = $dir_out->file( $design_id . '_oligos.log');

    my ( $result, $primer3_explain ) = $p3->run_primer3( $logfile->absolute, $region_bio_seq, # bio::seqI
            { SEQUENCE_TARGET => $target_sequence_mask ,
            } );
$DB::single=1;
    if ( $result->num_primer_pairs ) {
        INFO ( "$design_id genotyping primer region primer pairs: " . $result->num_primer_pairs );
        #add_primer3_result( $design_id => $result );
    }
    else {
        WARN ( "Failed to generate genotyping primer pairs for $design_id" );
        $failed_primer_regions{$design_id} = $primer3_explain;
    }


    my $primer_data = parse_primer3_results( $result );

#    use DesignCreate::Exception::Primer3FailedFindOligos;

#    if (%failed_primer_regions) {
#        DesignCreate::Exception::Primer3FailedFindOligos->throw(
#            regions             => [ keys %failed_primer_regions ],
#            primer_fail_reasons => \%failed_primer_regions,
#        );
#    }

    return $primer_data;
}


sub parse_primer3_results {
    my  $result  = shift;

    my $oligo_data;
    # iterate through each primer pair
    $oligo_data->{pair_count} = $result->num_primer_pairs;
    while (my $pair = $result->next_primer_pair) {
        # do stuff with primer pairs...
        my ($fp, $rp) = ($pair->forward_primer, $pair->reverse_primer);
        $oligo_data->{$fp->display_name} = parse_primer( $fp );
        $oligo_data->{$rp->display_name} = parse_primer( $rp );
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

    # outline of process:
    # query the design_oligos table for the design_id and the 5F or 3R primer,
    # join on the design_oligo_loci table to generate the genomic co-ordinates
    # Construct an input file for EnsEmbl to pull back the sequence for the region
    # call Primer 3 with appropriate options to generate primers.
    # update the genotyping oligos table with the generated oligos.
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

    my $chr_strand = $design_info->chr_strand == 1 ? 'plus' : 'minus';
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
Given design and schema
Returns a single sequence covering the whole region for Primer3 and a target_sequence_string that
indicates which part of the sequene is being targeted (and therefore should not be part of the primer
sequences).
=cut

sub get_EnsEmbl_region {
    my $params = shift;

    my $design_r = $params->{'schema'}->resultset('Design')->find($params->{'design_id'});
    my $design_info = LIMS2::Model::Util::DesignInfo->new( design => $design_r );
    my $design_oligos = $design_info->oligos;

    my $chr_strand = $design_info->chr_strand == 1 ? 'plus' : 'minus';
    my $slice_region;
    my $seq;

    my $start_oligo_field_width = 1000;
    my $end_oligo_field_width = 1000;

    if ( $chr_strand eq 'plus' ) {
        $slice_region = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{'5F'}->{'start'} - $start_oligo_field_width,
            $design_oligos->{'3R'}->{'end'} + $end_oligo_field_width,
            $design_info->chr_strand,
        );
        $seq = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_region->seq, -verbose => -1 );
    }
    elsif ( $chr_strand eq 'minus' ) {
        $slice_region = $design_info->slice_adaptor->fetch_by_region(
            'chromosome',
            $design_info->chr_name,
            $design_oligos->{'3R'}->{'start'} - $start_oligo_field_width,
            $design_oligos->{'5F'}->{'end'} + $end_oligo_field_width,
            $design_info->chr_strand,
        );
        $seq = Bio::Seq->new( -alphabet => 'dna', -seq => $slice_region->seq, -verbose => -1 )->revcom;
    }

    my $target_sequence_length = $seq->length  - $start_oligo_field_width - $end_oligo_field_width;
    my $target_sequence_string = $start_oligo_field_width . ',' . $target_sequence_length;

    return ($seq, $target_sequence_string, $target_sequence_length) ;

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

=head2 oligos_for_crispr_pair

Generate sequencing primer oligos for a crispr pair

These oligos should be 100b from the 5' end of the left crispr so that sequencing reads into the crispr itself.

For the right crispr, the primer should be 100b from the 3' end of the crispr, again so that sequencing
reads into the crispr itself

=cut

sub oligos_for_crispr_pair {

    return;
}

1;
