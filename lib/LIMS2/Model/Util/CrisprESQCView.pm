package LIMS2::Model::Util::CrisprESQCView;
use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::CrisprESQCViews

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ 'find_gene_crispr_es_qc' ]
};

use Log::Log4perl qw( :easy );
use List::Util qw( first );
use Try::Tiny;

=head2 find_gene_crispr_es_qc


=cut
sub find_gene_crispr_es_qc {
    my ( $model, $gene, $species_id ) = @_;

    my $gene_info = try{ $model->find_gene( { search_term => $gene, species => $species_id } ) };

    # if we dont find a gene via solr index just search directly against the gene_design table
    my $gene_id;
    if ( $gene_info ) {
        $gene_id = $gene_info->{gene_id};
    }
    else {
        $gene_id = $gene;
        $gene_info->{gene_symbol} = $gene;
    }

    my $design_summaries_rs = summary_rows_for_gene( $model, $gene_id, $species_id );

    my $gene_finder = sub { $model->find_genes( @_ ) };
    my %crispr_qc;
    while ( my $summary_row = $design_summaries_rs->next ) {
        # has accepted ep_pick_well and has crispr ep well
        if (   $summary_row->ep_pick_well_id
            && $summary_row->ep_pick_well_accepted
            && $summary_row->crispr_ep_well_id )
        {
            # TODO pile up piq qc against single ep_pick
            #      FEEDBACK from Wendy
            #      TEST output is ok, check qc is right
            #      UPDATED overnight, note this down somewhere
            my $data = ep_pick_crispr_es_qc_data( $model, $summary_row, \%crispr_qc, $gene_finder );
            piq_crispr_es_qc_data( $model, $summary_row, $data, $gene_finder);
        }
    }

    my @sorted_crispr_qc = map{ $crispr_qc{$_} } sort { $a cmp $b } keys %crispr_qc;
    return ( $gene_info, \@sorted_crispr_qc );
}

=head2 summary_rows_for_gene

For a gene find all its designs, then use this to find all the summary
rows which have an accepted ep_pick well along with a crispr_ep_well.
These should be all the ep_pick wells that have passed the crispr es qc.

=cut
sub summary_rows_for_gene {
    my ( $model, $gene_id, $species_id ) = @_;

    my $designs = $model->c_list_assigned_designs_for_gene(
        { gene_id => $gene_id, species => $species_id } );
    my @design_ids = map{ $_->id } @{ $designs };

    # grab distinct summary rows which have a accepted ep_pick well and a crispr_ep_well
    # this can return the same ep_pick wells with multiple PIQ grandparent wells
    my $design_summaries_rs = $model->schema->resultset('Summary')->search(
        {
            design_id             => { 'IN' => \@design_ids },
            ep_pick_well_id       => { '!=' => undef },
            crispr_ep_well_id     => { '!=' => undef },
            ep_pick_well_accepted => 1,
        },
        {
            columns => [
                qw( design_id
                    ep_pick_well_id ep_pick_plate_name ep_pick_well_name ep_pick_well_accepted
                    crispr_ep_well_id
                    piq_well_id piq_plate_name piq_well_name piq_well_accepted
                    )
            ],
            distinct => 1,
        }
    );

    return $design_summaries_rs;
}

=head2 ep_pick_crispr_es_qc_data

Find and format the crispr es qc data for the EP PICK well on the given
summary row. The row will have a accepted qc result because the well has
already been marked as accepted.

=cut
sub ep_pick_crispr_es_qc_data {
    my ( $model, $summary_row, $crispr_qc, $gene_finder ) = @_;

    my $ep_pick_well_name = $summary_row->ep_pick_plate_name . '_' . $summary_row->ep_pick_well_name;
    return $crispr_qc->{$ep_pick_well_name} if exists $crispr_qc->{$ep_pick_well_name};

    my %data;
    $data{ep_pick_well} = $ep_pick_well_name;
    my $ep_pick_well = $model->schema->resultset('Well')->find(
        $summary_row->ep_pick_well_id );

    # find the crispr es qc data
    try {
        $data{ep_pick_qc}= $ep_pick_well->genotyping_info( $gene_finder, 1 );
    };

    delete $data{ep_pick_qc}{es_qc_well_id};
    delete $data{ep_pick_qc}{gene};
    $data{ep_pick_qc}{well_name} = $ep_pick_well_name;
    $crispr_qc->{$ep_pick_well_name} = \%data;

    return \%data;
}

=head2 piq_crispr_es_qc_data

Find and format the crispr es qc data for the PIQ well on the given
summary row. If there is a accepted qc results use this, otherwise use
the first non accepted result available.

=cut
sub piq_crispr_es_qc_data {
    my ( $model, $summary_row, $data, $gene_finder ) = @_;

    return unless $summary_row->piq_well_id;

    my @qc_wells = $model->schema->resultset('CrisprEsQcWell')->search(
        {
            well_id  => $summary_row->piq_well_id,
        },
    );
    my $qc_well = first { $_->accepted } @qc_wells;
    $qc_well //= shift @qc_wells;

    my $qc_data;
    if ( $qc_well ) {
        try {
            $qc_data = $qc_well->format_well_data( $gene_finder, { truncate => 1 } );
        };
    }

    if ( $qc_data ) {
        my $piq_well_name = $summary_row->piq_plate_name . '_' . $summary_row->piq_well_name;
        delete $qc_data->{es_qc_well_id};
        delete $qc_data->{gene};
        $qc_data->{well_name} = $piq_well_name;

        $data->{piq_well} = $piq_well_name;
        $data->{piq_accepted} = $summary_row->piq_well_accepted;
        push @{ $data->{piq_qc} }, {
            piq_well => $piq_well_name,
            accepted => $summary_row->piq_well_accepted,
            qc       => $qc_data,
        }
    }

    return;
}

1;
