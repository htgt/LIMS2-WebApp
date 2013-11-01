package LIMS2::WebApp::Controller::Auth;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::Auth::VERSION = '0.121';
}
## use critic

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::Auth - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 login

=cut

sub login : Global {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');
    my $password = $c->req->param('password');
    my $goto     = $c->stash->{goto_on_success} || $c->req->param('goto_on_success') || $c->uri_for('/');

    $c->stash( goto_on_success => $goto );

    return unless $c->req->param('login');

    unless ( $username && $password ) {
        $c->stash( error_msg => "Please enter your username and password" );
        return;
    }

    if ( $c->authenticate( { name => lc($username), password => $password, active => 1 } ) ) {
        $c->flash( success_msg => 'Login successful' );
        return $c->res->redirect($goto);
    }
    else {
        $c->stash( error_msg => 'Incorrect username or password' );
    }

    return;
}

=head2 logout

=cut

sub logout : Global {
    my ( $self, $c ) = @_;

    $c->logout;

    $c->flash( info_msg => 'You have been logged out' );
    return $c->res->redirect( $c->uri_for('/login') );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
