package LIMS2::t::WebApp::Controller::API::Report;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::API::Report;
#use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/API/Report.pm - test class for LIMS2::WebApp::Controller::API::Report

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

sub all_tests  : Test(1)
{
    ok(1, "Test of LIMS2::WebApp::Controller::API::Report");

    ## The test below is commented out because the code for it in LIMS2 relies on cached files obtained by using the base URL of the running LIMS2 instance.
    ## In this test the base URL is localhost. The code for this test in LIMS2 will not be modified to fit the test at the moment unless decided otherwise.
    ## Note: there is a JS test for cached files.
    #my $mech = LIMS2::Test::mech();
    #$mech->get_ok("/api/confluence/report", { 'Content-Type' => 'text/html'});
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

