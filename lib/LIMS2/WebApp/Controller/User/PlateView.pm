package LIMS2::WebApp::Controller::User::PlateView;
use Moose;
use namespace::autoclean;
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::User::PlateView - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller to display plates in a widget for viewing and editing

=head1 METHODS

=cut

sub edit_plate :Path( '/user/edit_plate' ) :Args(0) {
    my ( $self, $c ) = @_;
$DB::single=1;

    $c->stash( template => 'user/pool/XepAppLoader.tt');
#    return $c->res->redirect( $c->uri_for('/user/XepAppLoader') );
}

=head1 AUTHOR

t87-developers

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
