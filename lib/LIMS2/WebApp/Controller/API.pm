package LIMS2::WebApp::Controller::API;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::API::VERSION = '0.431';
}
## use critic

use Moose;
use namespace::autoclean;
use Data::Serializer;
use Config::Tiny;

BEGIN {extends 'LIMS2::Catalyst::Controller::REST'; }

=head1 NAME

LIMS2::WebApp::Controller::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 begin

=cut

sub update_user_display_type : Path( '/api/update_user_display_type' ) : Args(0) :ActionClass( 'REST' ) {
}

sub update_user_display_type_POST {
    my ( $self, $c ) = @_;

    $c->session->{display_type} = $c->request->params->{display_type} || 'default';
    $self->status_ok( $c, entity => { success => 1 } );

    return;
}

sub auto : Private {
    my ( $self, $c ) = @_;
    # This allows a logged-in user to access the REST API without
    # further authentication, and provides an HTTP basic auth fallback
    # for programmatic access
    unless ( $c->user_exists ) {
        #my $username = delete $c->req->parameters->{ 'username' };
        #my $password = delete $c->req->parameters->{ 'password' };
        my $key = delete $c->req->headers->{pass};

        unless ( $key ) {
            $self->status_forbidden( $c, message => 'Key not specified' );
            $c->detach();
        }

        my $_conf = Config::Tiny->read($ENV{LIMS2_REST_CLIENT_CONFIG});
        my $serial = Data::Serializer->new();
        $serial = Data::Serializer->new(
            serializer  => 'Data::Dumper',
            digester    => 'SHA-256',
            cipher      => 'Blowfish',
            secret      => $_conf->{api}->{transport},
            compress    => 0,
        );

        my $frozen = $serial->thaw($key);

        unless ( $c->authenticate( { access_key => $frozen->{access}, secret_key => $frozen->{secret} }, 'rest' ) ) {
            $self->status_forbidden( $c, message => 'Key not correct' );
            $c->detach();
        }
    }

    if ( ! $c->session->{selected_species} ) {
        my $prefs = $c->model('Golgi')->retrieve_user_preferences( { id => $c->user->id } );
        $c->session->{selected_species} = $prefs->default_species_id;
    }

    return 1;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
