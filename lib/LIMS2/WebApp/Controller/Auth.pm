package LIMS2::WebApp::Controller::Auth;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::WebApp::Controller::Auth::VERSION = '0.511';
}
## use critic


use Moose;
use Crypt::CBC;
use Config::Tiny;
use namespace::autoclean;
use Data::Dumper;
use MIME::Lite;
use Email::Valid;

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
    my $protocol = $c->req->headers->header('X-FORWARDED-PROTO') // '';
    if($protocol eq 'HTTPS'){
        my $base = $c->req->base;
        $base =~ s/^http:/https:/;
        $c->req->base(URI->new($base));
        $c->req->secure(1);
    }

    $c->require_ssl;
    my $username = $c->req->param('username');
    my $password = $c->req->param('password');
    my $goto     = $c->stash->{goto_on_success} || $c->req->param('goto_on_success') || $c->uri_for('/');
    my $htgtsession = $c->stash->{htgtsession} || $c->req->param('htgtsession') || "";

    $c->log->debug("HTGT session: $htgtsession");
    $c->stash( goto_on_success => $goto, htgtsession => $htgtsession );

    return unless $c->req->param('login');

    unless ( $username && $password ) {
        $c->stash( error_msg => "Please enter your username and password" );
        return;
    }

    if ( $c->authenticate( { name => lc($username), password => $password, active => 1 } ) ) {
        my $prefs = $c->model('Golgi')->retrieve_user_preferences({ id => $c->user->id } );
        if ($prefs){
            $c->session->{selected_species} = $prefs->default_species_id;
            $c->session->{selected_pipeline} = $prefs->default_pipeline_id;
        }
    	# Only set the flash message if we are staying in lims2 webapp
        # FIXME: assuming we redirect to a http page, not another https page
    	my $app_root = quotemeta( $c->uri_for('/') );
    	$c->log->debug("App root uri: $app_root");
        if($goto=~/$app_root/){
            $c->flash( success_msg => 'Login successful' );
        }
        # If we have a htgt session id set a cookie that htgt can use
        # to check authentication
        if ($htgtsession){
            $c->log->debug('Writing LIMS2Auth cookie for htgt');
            my $conf_file = $ENV{LIMS2_HTGT_KEY}
                or die "Cannot write cookie for HTGT - no LIMS2_HTGT_KEY environment variable set.";

            my $conf = Config::Tiny->read($conf_file);
            my $key = $conf->{_}->{auth_key}
                or die "Cannot write cookie - no auth_key provided in $conf_file ";

            my $cookie_data = $htgtsession.":".lc($username);
            my $cipher = Crypt::CBC->new( -key => $key, -cipher => 'Blowfish');

            # FIXME: set domain depending on dev or live environment
            $c->res->cookies->{LIMS2Auth} = {
        	    value => $cipher->encrypt($cookie_data),
        	    expires => '+1h',
        	    domain => '.sanger.ac.uk',
            };
        }
        $c->log->debug("redirecting to $goto");
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

sub reset_password : Path('/reset_password') {

    my ( $self, $c ) = @_;
    $c->log->debug('reset_passord');
    my $username = $c->req->param("username");

    unless ($username){return}

        my $model   = $c->model('Golgi');

        my $user_rs = $model->schema->resultset("User")->find({name => $username});

    if ($username eq $user_rs->{_column_data}->{name}){

        $user_rs = $model->schema->resultset("User")->find({name => $username})->as_hash;

        my $password = $model->pwgen;

        $model->txn_do(
            sub {
                $model->set_user_password( { name => $user_rs->{name}, password => $password } );
                $self->email_notification($c, $username, $password);
            }
        );

	}else{

   	 $c->stash( error_msg => 'Incorrect email' );

	}
    return;
}

sub email_notification : Global {
    my ($self, $c, $username, $password) = @_;

    my $address = Email::Valid->address($username);

    my $validator = ($address ? 'yes' : 'no');

    if ($validator eq 'yes'){

        my $to = $username;
        my $from = 'htgt@sanger.ac.uk';
        my $subject = 'LIMS2 - Password Recovery';
        my $message = "Hello,\n\nYou recently requested to change your LIMS2 password.\nYour temporary password is: $password\n\nYou can log in to LIMS2 here:\nhttps://www.sanger.ac.uk/htgt/lims2//login\nWe recommend that you change the password to something you can remember.\nOnce you've logged in with the above credentials, you can change your password by clicking on your username on the top right of the page and selecting change password.\n\nAny questions or problems please email htgt\@sanger.ac.uk\nKind Regards,\nLIMS2 Team";

        my $msg = MIME::Lite->new(
            From     => $from,
            To       => $to,
            Subject  => $subject,
            Data     => $message
        );

        $msg->send;
        $c->flash( info_msg => 'Email Sent Successfully' );

    } else {
        $c->stash( error_msg => 'Not a valid email address, please contact htgt@sanger.ac.uk' );
    }
    return;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
