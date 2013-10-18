package LIMS2::WebApp::Controller::User::DesignTargets;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::DesignTargets::VERSION = '0.113';
}
## use critic

use Moose;
use LIMS2::Model::Util::DesignTargets qw( design_target_report_for_genes );
use LIMS2::Model::Constants qw( %UCSC_BLAT_DB );
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::DesignTargets - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path('/user/design_target_gene_search') :Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    $c->stash(
        genes => $c->request->param('genes') || undef,
    );

    return;
}

sub gene_report : Path('/user/design_target_report') {
    my ( $self, $c, $gene ) = @_;

    $c->assert_user_roles( 'read' );
    if ( !$c->request->param('genes') && !$gene ) {
        $c->flash( error_msg => "Please enter some gene names" );
        return $c->go('index');
    }

    my $report_type = $c->request->param( 'report_type' );

    my ( $design_targets_data, $search_terms ) = design_target_report_for_genes(
        $c->model('Golgi')->schema,
        $c->request->param('genes') || $gene,
        $c->session->{selected_species},
        $report_type,
        $c->request->param('off_target_algorithm'),
    );

    unless ( @{ $design_targets_data } ) {
        $c->flash( error_msg => "No design targets found matching search terms" );
    }

    if ( $report_type eq 'simple' ) {
        $c->stash( template => 'user/designtargets/simple_gene_report.tt');
    }
    else {
        $c->stash( template => 'user/designtargets/gene_report.tt');
    }

    $c->stash(
        design_targets_data => $design_targets_data,
        genes               => $c->request->param('genes') || $gene,
        search_terms        => $search_terms,
        species             => $c->session->{selected_species},
    );

    return;
}

sub crispr_pick : Path('/user/design_target_report_crispr_pick') : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );
    my $crispr_picks = $c->request->params->{crispr_pick};

    my $csv_data = "crispr_id,design_id\n";
    for my $pick ( @{ $crispr_picks } ) {
        my ( $crispr_id, $design_id ) = split /:/, $pick;
        $csv_data .= "$crispr_id,$design_id\n";
    }

    $c->response->content_type( 'text/csv' );
    $c->response->header( 'Content-Disposition' => "attachment; filename=crispr_picks.csv" );
    $c->response->body( $csv_data );
    return;
}

=head2 crisprs_ucsc_blat

Link to UCSC Blat page for set for crisprs for a design target.

=cut
sub crisprs_ucsc_blat : Path( '/user/crisprs_ucsc_blat' ) : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );

    my $species_id = $c->request->param('species') || $c->session->{selected_species};

    unless ( $c->request->param('sequence') ) {
        $c->stash( error_msg => "Must specify a fasta sequence string" );
        return;
    }

    my $ucsc_db = $UCSC_BLAT_DB{ lc($species_id) };

    $c->stash(
        sequence => $c->request->param('sequence'),
        species  => $species_id,
        uscs_db  => $ucsc_db,
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
