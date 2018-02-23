package LIMS2::t::WebApp::Controller::Auth;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::Auth;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/Auth.pm - test class for LIMS2::WebApp::Controller::Auth

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
};

=head2 before

Code to run before every test

=cut

sub before : Test(setup)
{
    #diag("running before test");
};

=head2 after

Code to run after every test

=cut

sub after  : Test(teardown)
{
    #diag("running after test");
};


=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup)
{
    #diag("running before all tests");
};

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown  : Test(shutdown)
{
    #diag("running after all tests");
};

=head2 all_tests

Code to execute all tests

=cut

sub all_tests  : Test(36)
{

    my $mech = unauthenticated_mech();

    {
	$mech->get_ok( '/login' );
	ok my $res = $mech->submit_form(
	    form_name => 'login_form',
	    fields    => { username => 'test_user@example.org', password => 'foobar' },
	    button    => 'login'
	), 'Login with invalid password';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/login', '...stays on the login page';
	like $res->content, qr/Incorrect username or password/, '...incorrect username/password error displayed';
    }

    {
	$mech->get_ok( '/login' );
	ok my $res = $mech->submit_form(
	    form_name => 'login_form',
	    fields    => { username => 'no_such_user@example.org', password => 'ahdooS1e' },
	    button    => 'login'
	), 'Login with incorrect username';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/login', '...stays on the login page';
	like $res->content, qr/Incorrect username or password/, '...incorrect username/password error displayed';
    }

    {
	$mech->get_ok( '/login' );
	ok my $res = $mech->submit_form(
	    form_name => 'login_form',
	    fields    => { username => 'test_user@example.org', password => 'ahdooS1e' },
	    button    => 'login'
	), 'Login with correct password';

	ok $res->is_success, '...response is_success';
	like $res->content, qr/Login successful/, '...login successful message is present';
    is $res->base->path, '/', '...redirected to "/"';
    }

    {
	$mech->get_ok( '/login' );
	ok my $res = $mech->submit_form(
	    form_name => 'login_form',
	    fields    => { username => 'new_user@example.org', password => 'aqbdK3v5d' },
	    button    => 'login'
	), 'First time login with correct password';

    ok $res->is_success, '...response is_success';
	like $res->content, qr/change password to access/, '...change password message is present';
    is $res->base->path, '/login', '...redirected to change password page';

    ok my $res_password = $mech->submit_form(
	    form_name => 'change_password_form',
	    fields    => { new_password => 'erbNf12k', new_password_confirm => 'erbNf1k' },
	    button    => 'change_password_submit'
	), 'Password and confirm password mismatch';

	ok $res_password->is_success, '...response is_success';
    is $res_password->base->path, '/user/change_password', '...stays on change password page';
	like $res_password->content, qr/confirm values do not match/, '...Password and comfirm password do not match error displayed';
    }

    {
    $mech->get_ok('/login');
    ok my $res = $mech->submit_form(
	    form_name => 'login_form',
	    fields    => { username => 'new_user@example.org', password => 'aqbdK3v5d' },
	    button    => 'login'
	), 'First time Logging in with correct username and password';

    ok $res->is_success, '...response is success';
	is $res->base->path, '/login', '...redirected to change password page';
    
    ok my $res_password = $mech->submit_form(
	    form_name => 'change_password_form',
	    fields    => { new_password => 'erbNf12k', new_password_confirm => 'erbNf12k' },
	    button    => 'change_password_submit'
	), 'Changing password';

	ok $res_password->is_success, '...response is_success';
	like $res_password->content, qr/Password successfully changed/, '...password sucessfully changed message is present';
    is $res_password->base->path, '/', '...redirected to "/"';
    }

    {
	$mech->get_ok( '/login' );
	ok my $res = $mech->submit_form(
	    form_name => 'login_form',
	    fields    => { username => 'new_user@example.org', password => 'erbNf12k' },
	    button    => 'login'
	), 'Login with new password';

	ok $res->is_success, '...response is_success';
	like $res->content, qr/Login successful/, '...login successful message is present';
    is $res->base->path, '/', '...redirected to "/"';
    }
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

