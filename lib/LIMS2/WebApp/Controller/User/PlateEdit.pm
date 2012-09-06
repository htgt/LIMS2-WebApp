package LIMS2::WebApp::Controller::User::PlateEdit;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::PlateEdit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub index :Path( '/user/edit_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $plate = $c->model('Golgi')->retrieve_plate( $c->request->params );

    $c->stash(
        plate => $plate,
    );
    return;
}

sub delete_plate :Path( '/user/delete_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    unless ( $params->{plate_id} ) {
        $c->flash->{error_msg} = 'No plate_id specified when trying to delete plate';
        $c->res->redirect( $c->uri_for('/user/browse_plates') );
        return;
    }

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi')->delete_plate( { id => $params->{plate_id} } );
                $c->flash->{success_msg} = 'Deleted plate ' . $params->{plate_name};
                $c->res->redirect( $c->uri_for('/user/browse_plates') );
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while deleting plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
                $c->res->redirect( $c->uri_for('/user/edit_plate', { id => $params->{plate_id} }) );
            };
        }
    );
}

sub rename_plate :Path( '/user/rename_plate' ) :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $c->request->params;

    unless ( $params->{plate_id} ) {
        $c->flash->{error_msg} = 'No plate_id specified';
        $c->res->redirect( $c->uri_for('/user/browse_plates') );
        return;
    }

    unless ( $params->{new_plate_name} ) {
        $c->flash->{error_msg} = 'You must specify a new plate name';
        $c->res->redirect( $c->uri_for('/user/edit_plate', { id => $params->{plate_id} }) );
        return;
    }

    $c->model('Golgi')->txn_do(
        sub {
            try{
                $c->model('Golgi') ->rename_plate(
                    { id => $params->{plate_id}, new_name => $params->{new_plate_name} } );

                $c->flash->{success_msg} = 'Renamed plate to ' . $params->{new_plate_name};
            }
            catch {
                $c->flash->{error_msg} = 'Error encountered while renaming plate: ' . $_;
                $c->model('Golgi')->txn_rollback;
            };
        }
    );

    $c->res->redirect( $c->uri_for('/user/edit_plate', { id => $params->{plate_id} }) );
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
