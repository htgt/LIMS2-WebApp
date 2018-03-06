package LIMS2::WebApp::Controller::User::PlateCopy;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::User::PlateCopy::VERSION = '0.490';
}
## use critic

use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::UI::PlateCopy - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    $c->assert_user_roles( 'edit' );
    return;
}

sub plate_from_copy :Path( '/user/plate_from_copy' ) :Args(0) {
    my ( $self, $c ) = @_;

    return;
}

sub plate_from_copy_process :Path( '/user/plate_from_copy_process' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $from_plate_name = $c->request->params->{'from_plate_name'};
    my $to_plate_name = $c->request->params->{'to_plate_name'};
    if ( !$from_plate_name || !$to_plate_name ){
        $c->flash->{'error_msg'} = 'Specify both "from" plate name and "to" plate name';
        return $c->res->redirect($c->uri_for( '/user/plate_from_copy' ));
    }
    if ( $from_plate_name eq $to_plate_name){
        $c->flash->{'error_msg'} = '"from" plate name cannot be the same as "to" plate name';
        return $c->res->redirect($c->uri_for( '/user/plate_from_copy' ));
    }
    # Copy the plate
    my $model = $c->model('Golgi');
    $c->clear_flash();
    my $error;
    try {
        $model->txn_do( sub {
            $model->create_plate_by_copy(
                { from_plate_name  =>      $from_plate_name,
                  to_plate_name    =>      $to_plate_name,
                  created_by       =>      $c->user->name },
            );
        });
    }
    catch {
        $c->flash->{'error_msg'} = 'Error copying plate: ' . $_;
        $error = 1;
    };
    # Success:
    if ( ! $error ){
        $c->flash->{'success_msg'} = $from_plate_name . ' was copied to ' . $to_plate_name . ' successfully.';
    }
    return $c->res->redirect($c->uri_for( '/user/plate_from_copy' ));

}

=head1 AUTHOR

David Parry-Smith

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
