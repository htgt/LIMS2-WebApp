package LIMS2::WebApp::Controller::Auth;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

LIMS2::WebApp::Controller::Auth - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched LIMS2::WebApp::Controller::Auth in Auth.');
}

=head2 login

=cut

sub login : Global {
    my ( $self, $c ) = @_;

    my $username = $c->req->param( 'username' );
    my $password = $c->req->param( 'password' );
    my $goto     = $c->req->param( 'goto_on_success' ) || '/';

    return unless defined $username and defined $password;
    
    if ( $c->authenticate( { user_name => $username, password => $password } ) ) {
        $c->flash( status_msg => 'Login successful' );
        return $c->res->redirect( $c->uri_for( $goto ) );
    }
    else {
        $c->stash( error_msg => 'Incorrect username or password' );
    }        
}

=head2 logout

=cut

sub logout : Global {
    my ( $self, $c ) = @_;

    $c->logout;

    $c->flash( status_msg => 'You have been logged out' );
    return $c->res->redirect( $c->uri_for( '/login' ) );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
