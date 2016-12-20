package LIMS2::t::WebApp::Controller::User::AddWell;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::AddWell;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/AddWell.pm - test class for LIMS2::WebApp::Controller::User::AddWell

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

# BEGIN
# {
#     # compile time requirements
#     #{REQUIRE_PARENT}
#     use Log::Log4perl qw( :easy );
#     Log::Log4perl->easy_init( $FATAL );
# };

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

#
#
#
# USES LEGACY FIXTURE DATA!
# for some reason doesn't load dynamic fixture csvs
# below is the data for the dynamic fixtures
#
# ok my $res = $mech->submit_form(
#     fields => {
#         parent_plate        => 'HCL16',
#         parent_well         => 'A01',
#         target_plate        => 'HCL0016_A',
#         template_well       => 'A02',
#         target_well         => 'B01',
#     },
#     button => 'add_well_to_plate',
# );
#
#
#

sub all_tests  : Tests {
    ok(1, "Test of LIMS2::WebApp::Controller::User::AddWell");

	my $mech = LIMS2::Test::mech();
    $mech->get_ok('/user/add_well');

    ok my $res = $mech->submit_form(
            fields => {
                parent_plate        => 'FEP0017',
                parent_well         => 'C01',
                target_plate        => 'FEPD0017_4',
                template_well       => 'E11',
                target_well         => 'E13',
            },
            button => 'add_well_to_plate',
        );

    ok $res->is_success, '...response is_success';

    $mech->content_contains('Well successfully added');

}

=head1 AUTHOR

Josh Kent
Lars G. Erlandsen

=cut

## use critic

1;

__END__