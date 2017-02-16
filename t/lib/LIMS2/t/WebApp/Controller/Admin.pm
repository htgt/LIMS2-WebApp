package LIMS2::t::WebApp::Controller::Admin;

use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::Admin;

use LIMS2::Test model => { classname => __PACKAGE__ };

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/Admin.pm - test class for LIMS2::WebApp::Controller::Admin

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

sub all_tests  : Tests
{
    ok(1, "Test of LIMS2::WebApp::Controller::Admin");

    my $mech = LIMS2::Test::mech();

    note( "Tests for Announcements" );

    $mech->get_ok( '/admin/announcements' );
    $mech->title_is( 'LIMS2 - Announcements' );

    note( "Create announcement" );

    $mech->get_ok( '/admin/announcements/create_announcement' );
    $mech->title_is( 'LIMS2 - Create Announcement' );

    ok my $res = $mech->submit_form(
    	form_id 	=> 'create_announcement_form',
    	fields 		=> {
    		message  		=> 'Message test 1',
    		expiry_date 	=> '01/01/2050',
    		priority 		=> 'normal',
    		webapp 			=> 'LIMS2',
    	},
    	button 		=> 'create_announcement',
    ), 'Submit form with valid data';

    ok (1,$mech->content);

    ok $res->is_success, '...response is success';
    $mech->base_like( qr{/admin/announcements} );
    $mech->content_contains('Message successfully created');
}

=head1 AUTHOR

Josh Kent

=cut

## use critic

1;

__END__

