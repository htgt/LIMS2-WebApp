package LIMS2::t::WebApp::Controller::PublicReports;

use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::PublicReports;

use LIMS2::Test model => { classname => __PACKAGE__ };
use strict;


## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/PublicReports.pm - test class for LIMS2::WebApp::Controller::PublicReports

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

sub all_tests  : Tests {
    ok(1, "Test of LIMS2::WebApp::Controller::PublicReports");


    my $barcode = "1117507060";
    my $well_name = "A01";
    my $plate_name = "HUFP0043_1_A";


    my $mech = LIMS2::Test::mech();
    $mech->get_ok('/public_reports/well_genotyping_info_search');
    $mech->get_ok('/public_reports/well_genotyping_info/1117507060');
    $mech->content_contains($plate_name);
    $mech->content_contains($well_name);
    $mech->content_contains('KOLF_2_C1');
    $mech->content_contains('CGGTCTCCATCCTACAAACACGG');
    $mech->content_contains('HGNC:30801');


    $mech->get_ok('/public_reports/well_genotyping_info/HUFP0043_1_A/A01');
    $mech->content_contains($barcode);
    $mech->content_contains('KOLF_2_C1');
    $mech->content_contains('CGGTCTCCATCCTACAAACACGG');
    $mech->content_contains('HGNC:30801');


}

=head1 AUTHOR

Josh Kent
based on template by
Lars G. Erlandsen

=cut

## use critic

1;

__END__

