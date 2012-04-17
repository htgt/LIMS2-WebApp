package LIMS2::WebApp::Controller::API::QcRuns;
use Moose;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::QcRuns - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub qc_runs :Path( '/api/qc_runs' ) :Args(0) :ActionClass( 'REST' ) { }

=head2 GET /api/qc_runs

Retrieve list of QcRuns

=cut

sub qc_runs_GET {
    my ( $self, $c ) = @_;

    my $qc_runs = $c->model('Golgi')->retrieve_list(
        QcRuns => { }, { columns => [ qw( id ) ] } );

    $self->status_ok(
        $c,
        entity => { map { $_->id => $c->uri_for( '/api/qc_run/'
                        . $_->id )->as_string } @{ $qc_runs } },
    );
}

=head2 POST /api/qc_runs

Create a QcRun

=cut

sub qc_runs_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    my $golgi - $c->model( 'Golgi' );

    my $qc_run;
    $golgi->txn_do(
        sub {
            $qc_run = $golgi->create_qc_run( $c->request->data );
        }
    );

    $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_run/', $qc_run->id ),
        entity   => $qc_run,
    );
}

sub qc_run :Path( '/api/qc_run' ) :Args(1) :ActionClass( 'REST' ) { }

=head2 GET /api/qc_run

Retrieve a specific qc_run, by qc_run_id

=cut

sub qc_run_GET {
    my ( $self, $c, $qc_run_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $qc_run = $c->model('Golgi')->retrieve( QcRuns => { id => $qc_run_id } );

    return $self->status_ok(
        $c,
        entity => $qc_run,
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
