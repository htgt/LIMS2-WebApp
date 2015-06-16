package LIMS2::Model::Util::CrisprESQCView;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::CrisprESQCView::VERSION = '0.322';
}
## use critic

use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::CrisprESQCViews

=head1 DESCRIPTION

Helper module for displaying Crispr ES QC Data

=cut

use Sub::Exporter -setup => {
    exports => [ 'find_gene_crispr_es_qc' ]
};

use Log::Log4perl qw( :easy );
use List::Util qw( first );
use Try::Tiny;

=head2 find_gene_crispr_es_qc

Find all the accepted crispr es qc ep_pick wells for a given gene.
For each of these wells find the child PIQ wells and any crispr es qc
that belongs to those PIQ well.

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

    my $ep_pick_wells = ep_pick_wells_for_gene( $model, $gene_id, $species_id );

    # format_well_data takes a sub ref that normally wraps around $model->find_genes
    # but since we only have one gene here we can use the following:
    my $gene_finder = sub { return { $gene => $gene_info } };
    my @crispr_qc;
    for my $ep_pick_well ( @{ $ep_pick_wells } ) {
        my %data;
        next unless ep_pick_crispr_es_qc_data( $model, $ep_pick_well, \%data, $gene_finder );
        piq_crispr_es_qc_data( $model, $ep_pick_well, \%data, $gene_finder );
        push @crispr_qc, \%data;
    }

    my @sorted_crispr_qc
        = sort { $a->{ep_pick_qc}{well_name} cmp $b->{ep_pick_qc}{well_name} } @crispr_qc;
    return ( $gene_info, \@sorted_crispr_qc );
}

=head2 ep_pick_wells_for_gene

Find all the accepted ep_pick wells for a given gene.
This is done by finding all the designs for the gene and the linked design wells.
For each of the design wells descend though the well hierarchy to locate all
the accepted wells on EP_PICK type plates.

=cut
sub ep_pick_wells_for_gene {
    my ( $model, $gene_id, $species_id ) = @_;

    my $designs = $model->c_list_assigned_designs_for_gene(
        { gene_id => $gene_id, species => $species_id } );
    my @design_wells = map{ @{ $_->design_wells } } @{ $designs };

    my @ep_pick_wells;
    for my $design_well ( @design_wells ) {
        my $descendants = $design_well->descendants->depth_first_traversal( $design_well, 'out' );
        next unless $descendants;
        while( my $descendant = $descendants->next ) {
            if ( $descendant->plate->type_id eq 'EP_PICK' ) {
                push @ep_pick_wells, $descendant if $descendant->is_accepted;
            }
        }
    }

    return \@ep_pick_wells;
}

=head2 ep_pick_crispr_es_qc_data

Find and format the crispr es qc data for the EP PICK well, if present.

=cut
sub ep_pick_crispr_es_qc_data {
    my ( $model, $ep_pick_well, $data, $gene_finder ) = @_;

    my $qc_well = $model->schema->resultset('CrisprEsQcWell')->search(
        {
            well_id       => $ep_pick_well->id,
            'me.accepted' => 1,
        },
        {
            prefetch => [ { 'well' => 'plate' }, 'crispr_es_qc_run' ],
        }
    )->first;
    return unless $qc_well;

    my $qc_run = $qc_well->crispr_es_qc_run;
    try {
        $data->{ep_pick_qc}
            = $qc_well->format_well_data( $gene_finder, { truncate => 1 }, $qc_run, [] )
    }
    catch{
        WARN( "Error formating crispr qc well data: $_" );
    };
    return unless exists $data->{ep_pick_qc};

    delete $data->{ep_pick_qc}{gene};
    $data->{ep_pick_qc}{qc_run_id} = $qc_run->id;
    $data->{ep_pick_qc}{well_name} = $ep_pick_well->as_string;
    $data->{accepted} = $qc_well->accepted;

    return 1;
}

=head2 piq_crispr_es_qc_data

For a EP PICK well find all descendant PIQ wells, then find all
the crispr es qc results for these PIQ wells.

=cut
sub piq_crispr_es_qc_data {
    my ( $model, $ep_pick_well, $data, $gene_finder ) = @_;

    my $descendants = $ep_pick_well->descendants->depth_first_traversal( $ep_pick_well, 'out' );
    return unless $descendants;

    my @piq_wells;
    while( my $descendant = $descendants->next ) {
        if ( $descendant->plate->type_id eq 'PIQ' ) {
            push @piq_wells, $descendant;
        }
    }
    return unless @piq_wells;

    my @qc_wells = $model->schema->resultset('CrisprEsQcWell')->search(
        {
            well_id  => { 'IN' => [ map{ $_->id } @piq_wells ] }
        },
        {
            prefetch => [ { 'well' => 'plate' }, 'crispr_es_qc_run' ],
        }
    );

    for my $qc_well ( @qc_wells ) {
        my $qc_run = $qc_well->crispr_es_qc_run;
        my $qc_data = try { $qc_well->format_well_data( $gene_finder, { truncate => 1 }, $qc_run, [] ) };
        next unless $qc_data;

        $qc_data->{qc_run_id} = $qc_run->id;
        delete $qc_data->{gene};

        my $piq_well = $qc_well->well;
        $qc_data->{well_name} = $piq_well->as_string;

        push @{ $data->{piq_qc} }, {
            accepted => $qc_well->accepted,
            qc       => $qc_data,
        }
    }

    return;
}

1;
