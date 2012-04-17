package LIMS2::WebApp::Controller::API::QcSequencingProject;
use Moose;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::QcSequencingProject - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub qc_sequencing_projects :Path( '/api/qc_sequencing_projects' ) :Args(0) :ActionClass('REST') { }

=head2 GET /api/qc_sequencing_projects

Retrieve list of QcSeqReads

=cut

sub qc_sequencing_projects_GET {
    my ( $self, $c ) = @_;

    my $qc_sequencing_projects = $c->model('Golgi')->retrieve_list(
        QcSequencingProject => { }, { columns => [ qw( name ) ] } );

    $self->status_ok(
        $c,
        entity => { map { $_->name => $c->uri_for( '/api/qc_sequencing_project/'
                        . $_->name )->as_string } @{ $qc_sequencing_projects } },
    );
}

=head2 POST /api/qc_sequencing_projects

Create a QcSequencingProject

=cut

sub qc_sequencing_projects_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my $qc_sequencing_project = $c->model( 'Golgi' )->create_qc_sequencing_project( $c->request->data );

    $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_sequencing_project/', $qc_sequencing_project->name ),
        entity   => $qc_sequencing_project,
    );
}

sub qc_sequencing_project :Path( '/api/qc_sequencing_project' ) :Args(1) :ActionClass( 'REST' ) { }

=head2 GET /api/qc_sequencing_project

Retrieve a specific QcSequencingProject, by qc_sequencing_project

=cut

sub qc_sequencing_project_GET {
    my ( $self, $c, $qc_sequencing_project ) = @_;

    $c->assert_user_roles( 'read' );

    my $qc_sequencing_project = $c->model('Golgi')->retrieve(
        QcSequencingProject => { name => $qc_sequencing_project }
    );

    return $self->status_ok(
        $c,
        entity => $qc_sequencing_project
    );
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
