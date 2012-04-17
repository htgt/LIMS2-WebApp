package LIMS2::WebApp::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 begin

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    # This allows a logged-in user to access the REST API without
    # further authentication, and provides an HTTP basic auth fallback
    # for programmatic access
    unless ( $c->user_exists ) {
        return $c->authenticate( { realm => 'LIMS2 API' }, 'basic' );        
    }
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
