package LIMS2::WebApp::Controller::Auth;
use Moose;
use Crypt::CBC;
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
    my $htgtsession = $c->stash->{htgtsession} || $c->req->param('htgtsession');
    
    $c->log->debug("HTGT session: $htgtsession");
    $c->stash( goto_on_success => $goto, htgtsession => $htgtsession );

    return unless $c->req->param('login');

    unless ( $username && $password ) {
        $c->stash( error_msg => "Please enter your username and password" );
        return;
    }

    if ( $c->authenticate( { name => lc($username), password => $password, active => 1 } ) ) {
    	
    	# Only set the flash message if we are staying in lims2 webapp
    	my $app_root = quotemeta( $c->req->base );
    	$c->log->debug("App root uri: $app_root");
        if($goto=~/$app_root/){
            $c->flash( success_msg => 'Login successful' );
        }
        
        # If we have a htgt session id set a cookie that htgt can use 
        # to check authentication
        if ($htgtsession){

            $c->log->debug('Writing LIMS2Auth cookie for htgt');
            
        	# FIXME!! get this from config file - it will not be "password"!
        	my $key = "password";            
            my $cookie_data = $htgtsession.":".lc($username);
            my $cipher = Crypt::CBC->new( -key => $key, -cipher => 'Blowfish');
            
            # FIXME: set domain depending on dev or live environment
            $c->res->cookies->{LIMS2Auth} = { 
        	    value => $cipher->encrypt($cookie_data), 
        	    expires => '+1h',
        	    domain => '.internal.sanger.ac.uk',
            };
        }
        
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
