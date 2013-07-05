package LIMS2::WebApp::Controller::User::DesignTargets;
use Moose;
use LIMS2::Model::Util::DesignTargets qw( design_target_report_for_genes );
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

sub gene_report : Path('/user/design_target_report') : Args(0) {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'read' );
    unless ( $c->request->param('genes') ) {
        $c->stash( error_msg => "Please enter some gene names" );
        return $c->go('index');
    }

    my ( $design_targets_data, $search_terms ) = design_target_report_for_genes(
        $c->model('Golgi')->schema,
        $c->request->param('genes'),
        $c->session->{selected_species},
    );

    $c->stash(
        design_targets_data => $design_targets_data,
        genes               => $c->request->param('genes'),
        search_terms        => $search_terms,
        species             => $c->session->{selected_species},
    );

    return;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
