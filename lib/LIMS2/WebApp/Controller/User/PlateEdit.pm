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

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
