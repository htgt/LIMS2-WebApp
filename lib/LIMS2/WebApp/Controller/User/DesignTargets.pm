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
    my @genes = grep { $_ } map{ chomp; $_; } split /\s/, $c->request->param('genes');

    my $design_targets_data = design_target_report_for_genes(
            $c->model('Golgi')->schema, \@genes, $c->session->{selected_species} );

    $c->stash(
        design_targets_data => $design_targets_data,
        search_genes => $c->request->param('genes'),
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
