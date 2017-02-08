package LIMS2::t::WebApp::Controller::User::EditWells;

use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::EditWells;

use LIMS2::Test model => { classname => __PACKAGE__ };
use strict;


## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/EditWells.pm - test class for LIMS2::WebApp::Controller::User::EditWells

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
    ok(1, "Test of LIMS2::WebApp::Controller::User::EditWells");

    my $mech = LIMS2::Test::mech();

    $mech->get_ok( '/user/add_well' );
    $mech->title_is('Add Well');
    ok my $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HCL16',
            parent_well         => 'A01',
            target_plate        => 'HCL0016_A',
            template_well       => 'A02',
            target_well         => 'D04',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Well successfully added');
    $mech->content_contains('duplicate key value violates unique constraint');

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HL16Z',
            parent_well         => 'A01',
            target_plate        => 'HCL0016_A',
            template_well       => 'A02',
            target_well         => 'D01',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to retrieve well: HL16Z_A01');

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HCL16',
            parent_well         => 'Z01',
            target_plate        => 'HCL0016_A',
            template_well       => 'A02',
            target_well         => 'D01',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to retrieve well: HCL16_Z01');

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HCL16',
            parent_well         => 'A01',
            target_plate        => 'HZL0016_A',
            template_well       => 'A02',
            target_well         => 'D01',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to retrieve well: HZL0016_A_A02');

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HCL16',
            parent_well         => 'A01',
            target_plate        => 'HCL0016_A',
            template_well       => 'AZ02',
            target_well         => 'D01',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to retrieve well: HCL0016_A_AZ02');

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HCL16',
            parent_well         => 'A01',
            target_plate        => 'HCL0016_A',
            template_well       => 'Z02',
            target_well         => 'D01',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    );
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to retrieve well: HCL0016_A_Z02');

}

=head1 AUTHOR

Josh Kent

=cut

## use critic

1;

#__END__