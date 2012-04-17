package LIMS2::WebApp::Controller::API::QcTestResult;
use Moose;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::QcTestResult - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub qc_test_results :Path( '/api/qc_test_results' ) :Args(0) :ActionClass( 'REST' ) { }

=head2 GET /api/qc_test_results

Retrieve list of QcTestResults

=cut

sub qc_test_results_GET {
    my ( $self, $c ) = @_;

    my $qc_test_result = $c->model('Golgi')->retrieve_list(
        QcTestResult => { }, { columns => [ qw( id ) ] } );

    $self->status_ok(
        $c,
        entity => { map { $_->id => $c->uri_for( '/api/qc_test_result/'
                        . $_->id )->as_string } @{ $qc_test_result } },
    );
}

=head2 POST /api/qc_test_results

Create a QcTestResult

=cut

sub qc_test_results_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );

    my $qc_test_result = $c->model( 'Golgi' )->create_qc_test_result( $c->request->data );

    $self->status_created(
        $c,
        location => $c->uri_for( '/api/qc_test_result/', $qc_test_result->id ),
        entity   => $qc_test_result,
    );
}

sub qc_test_result :Path( '/api/qc_test_result' ) :Args(1) :ActionClass( 'REST' ) { }

=head2 GET /api/qc_test_result

Retrieve a specific QcTestResult, by qc_test_result_id

=cut

sub qc_test_result_GET {
    my ( $self, $c, $qc_test_result_id ) = @_;

    $c->assert_user_roles( 'read' );

    my $qc_test_result = $c->model('Golgi')->retrieve( QcTestResult => { id => $qc_test_result_id } );

    return $self->status_ok(
        $c,
        entity => $qc_test_result,
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
