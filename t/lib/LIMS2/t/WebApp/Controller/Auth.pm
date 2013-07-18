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

sub all_tests  : Test(15)
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
	), 'Login with correct username and password';

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

