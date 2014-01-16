package LIMS2::Model::Util::OligoSelection;
use strict;
use warnings FATAL => 'all';

use Moose;

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

use Log::Log4perl qw( :easy );

sub primer_driver {
    my %params;

    my $params{$schema} = shift;
    my $params{$design_id} = shift;
    my $params{$assembly} = shift;

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
    my $gibson_design_oligos_rs = gibson_design_oligos_rs( $params->{$schema}, $params->{$design_id} );

    my %genotyping_primers;
    update_primer_type( '5F', \%genotyping_primers, $gibson_design_oligos_rs, $params->{$assembly});
    update_primer_type( '3R', \%genotyping_primers, $gibson_design_oligos_rs, $params->{$assembly});

    return \%genotyping_primers;
}


=head2 

=cut

sub get_EnsEmbl_sequence {


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
