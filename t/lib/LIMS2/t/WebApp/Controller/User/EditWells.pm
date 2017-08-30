package LIMS2::t::WebApp::Controller::User::EditWells;

use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::EditWells;

use LIMS2::Test model => { classname => __PACKAGE__ };
use File::Temp ':seekable';
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

    note( "Single well added" );

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
    ), 'Submit form with valid data';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Well successfully added');

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
    ), 'Submit form with invalid parent_plate field';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

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
    ), 'Submit form with invalid parent_well field - XNN';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HCL16',
            parent_well         => 'H01',
            target_plate        => 'HCL0016_A',
            template_well       => 'A02',
            target_well         => 'D01',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    ), 'Submit form with valid but non existant parent_well field - XNN - 2';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to retrieve well: HCL16_H01');

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
        form_id => 'add_well_to_plate_form',
        fields => {
            parent_plate        => 'HCL16',
            parent_well         => 'ZX01',
            target_plate        => 'HCL0016_A',
            template_well       => 'A02',
            target_well         => 'D01',
            csv                 => '0',
        },
        button => 'add_well_to_plate',
    ), 'Submit form with valid but non-existant parent_well field - XXNN';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

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
    ), 'Submit form with invalid target_plate field';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

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
    ), 'Submit form with invalid template_well field - XXNN';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

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
    ), 'Submit form with valid but non-existant template_well field - XNN';
    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');



    note( "CSV of wells to add" );

    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print( "parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HCL16,A01,HCL0016_A,A02,D01\n"
        . "HCL16,A01,HCL0016_A,A02,D06");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';
    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'upload file with valid data';

    ok $res->is_success, '...response is success';
    #ok(1, $mech->content);
    $mech->content_contains('Successfully created wells:');

    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HZL16,A01,HCL0016_A,A02,D01\n"
        . "HZL16,A01,HCL0016_A,A02,D06");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';

    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'upload file with invalid data in position 1';

    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HCL16,Z01,HCL0016_A,A02,D01\n"
        . "HCL16,Z01,HCL0016_A,A02,D06");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';

    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'upload file with invalid data in position 2 - XNN';

    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HCL16,ZX01,HCL0016_A,A02,D01\n"
        . "HCL16,ZX01,HCL0016_A,A02,D06");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';

    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'upload file with invalid data in position 2 - XXNN';

    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HCL16,A01,HZL0016_A,A02,D01\n"
        . "HCL16,A01,HZL0016_A,A02,D06");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';

    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'upload file with invalid data in position 3';

    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HCL16,A01,HCL0016_A,Z02,D01\n"
        . "HCL16,A01,HCL0016_A,Z02,D06");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';

    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'upload file with invalid data in position 4 - XNN';

    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HCL16,A01,HCL0016_A,ZX02,D01\n"
        . "HCL16,A01,HCL0016_A,ZX02,D06");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';

    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'upload file with invalid data in position 4 - XXNN';

    ok $res->is_success, '...response is success';
    $mech->content_contains('Unable to validate data');

    $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("parent_plate,parent_well,target_plate,template_well,target_well\n"
        . "HCL16,A01,HCL0016_A,A02,D07\n"
        . "HCL16,A01,HCL0016_A,A02,D08");
    $test_file->seek( 0, 0 );

    is $res->base->path, '/user/add_well', 'we are still on importer page';

    ok $res = $mech->submit_form(
    form_id => 'add_well_to_plate_csv_form',
    fields => {
        csv => '1',
        csv_upload => $test_file->filename,
    },
    button => 'add_well_csv_upload'
    ), 'Successfully created wells:';

    ok $res->is_success, '...response is success';
    $mech->content_contains('Successfully created wells:');
}

=head1 AUTHOR

Josh Kent

=cut

## use critic

1;

#__END__