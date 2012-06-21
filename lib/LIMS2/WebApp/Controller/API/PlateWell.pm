package LIMS2::WebApp::Controller::API::PlateWell;
use Moose;
use namespace::autoclean;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API::PlateWell - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub plate :Path '/api/plate' :Args(0) :ActionClass('REST') {
}

sub plate_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $plate = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_plate( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $plate );
}

sub plate_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $plate = $c->model('Golgi')->txn_do(
        sub {
            shift->create_plate( $c->request->params )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/plate', { id => $plate->id } ),
        entity => $plate
    );
}

sub well :Path '/api/well' :Args(0) :ActionClass('REST') {
}

sub well_GET {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('read');

    my $well = $c->model('Golgi')->txn_do(
        sub {
            shift->retrieve_well( $c->request->params )
        }
    );

    return $self->status_ok( $c, entity => $well );
}

sub well_POST {
    my ( $self, $c ) = @_;

    $c->assert_user_roles('edit');

    my $well = $c->model('Golgi')->txn_do(
        sub {
            shift->create_well( $c->request->params )
        }
    );

    return $self->status_created(
        $c,
        location => $c->uri_for( '/api/well', { id => $well->id } ),
        entity => $well
    );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
