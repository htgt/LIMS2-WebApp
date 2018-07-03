package LIMS2::t::WebApp::Controller::User::WellData;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::WellData;

use LIMS2::Test model => { classname => __PACKAGE__ }, 'mech';
use File::Temp ':seekable';

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/WellData.pm - test class for LIMS2::WebApp::Controller::User::WellData

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
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
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

sub concentration_upload  : Test(23)
{
    my $mech = mech();

    note("upload no spreadsheet");
    $mech->get_ok('/user/select_species?species=Human');
    $mech->get_ok('/user/dna_concentration_upload');
    $mech->title_is('DNA Concentration Upload');
    ok $mech->click_button( name => 'spreadsheet' ), 'submit without spreadsheet ok';
    $mech->content_contains('No file uploaded');

    note("upload spreadsheet");
    $mech->get_ok('/user/dna_concentration_upload');
    $mech->title_is('DNA Concentration Upload');
    my $example_ss_path = 'root/static/files/qc_upload/dna_concentrations.xlsx';
    ok $mech->submit_form(
    	form_id => 'dna_concentration_upload',
    	fields => {
    		spreadsheet => 'spreadsheet',
    		datafile => $example_ss_path,
    	},
    	button  => 'spreadsheet',
    ), 'submit with spreadsheet ok';
    $mech->content_contains('JG2');

    note("no plates specified");
    $mech->form_number(2);
    ok $mech->click_button( name => 'update' );
    $mech->content_contains('There were no plate updates to run');

    note("plate does not exist");
    $mech->back;
    $mech->form_number(2);
    $mech->field('JG2_map','rubbish');
    ok $mech->click_button( name => 'update' );
    $mech->content_contains('plate_name, is invalid: existing_plate_name');

    note("plate is not DNA");
    $mech->back;
    $mech->form_number(2);
    $mech->field('JG2_map','HCL1');
    ok $mech->click_button( name => 'update' );
    $mech->content_contains('expected plates of type(s) DNA');

    note("plate update");
    $mech->back;
    $mech->form_number(2);
    $mech->field('JG2_map','HCL_DNA');
    ok $mech->click_button( name => 'update');
    $mech->content_contains('Uploaded dna status information onto plate HCL_DNA');

    ok my $well = model->retrieve_well({ plate_name=>'HCL_DNA', well_name=>'A01'});
    is $well->well_dna_status->pass, 1, 'DNA status is correct';
    is $well->well_dna_status->concentration_ng_ul, 117.65911207533, 'DNA concentration is correct';

    note("repeated plate update fails");
    $mech->back;
    $mech->form_number(2);
    $mech->field('JG2_map','HCL_DNA');
    ok $mech->click_button( name => 'update');
    $mech->content_contains('Well HCL_DNA_A01 already has a dna status');
}

sub egel_status_upload : Tests(22) {
    my $mech = mech();

    note("upload no plate name");
    $mech->get_ok('/user/select_species?species=Human');
    $mech->get_ok('/user/dna_quality_update');
    $mech->title_is('DNA EGel Status Update');
    ok $mech->click_button( name => 'update_dna_quality' ), 'submit without plate name ok';
    $mech->content_contains('You must specify a plate name');

    note("upload no spreadsheet");
    $mech->get_ok('/user/dna_quality_update');
    ok $mech->submit_form(
        form_id => 'dna_quality_update',
        fields => {
            plate_name => 'HCL_DNA',
        },
        button  => 'update_dna_quality',
    ), 'submit without spreadsheet ok';
    $mech->content_contains('No csv file with dna quality data specified');

    note("plate does not exist");
    $mech->get_ok('/user/dna_quality_update');
    my $example_ss_path = 'root/static/test/data/egel_test.csv';
    ok $mech->submit_form(
        form_id => 'dna_quality_update',
        fields => {
            datafile => $example_ss_path,
            plate_name => 'rubbish',
        },
        button  => 'update_dna_quality',
    ), 'submit with plate that does not exist';
    $mech->content_contains('plate_name, is invalid: existing_plate_name');


    note("plate is not DNA");
    $mech->get_ok('/user/dna_quality_update');
    ok $mech->submit_form(
        form_id => 'dna_quality_update',
        fields => {
            datafile => $example_ss_path,
            plate_name => 'HCL1',
        },
        button  => 'update_dna_quality',
    ), 'submit with non DNA plate';
    $mech->content_contains('Invalid plate type');

    note("plate update");
    $mech->get_ok('/user/dna_quality_update');
    ok $mech->submit_form(
        form_id => 'dna_quality_update',
        fields => {
            datafile => $example_ss_path,
            plate_name => 'HCL_DNA',
        },
        button  => 'update_dna_quality',
    ), 'dna egel pass data uploaded';
    $mech->content_contains('Uploaded dna quality information onto plate HCL_DNA');

    my $well = model->retrieve_well({ plate_name=>'HCL_DNA', well_name=>'A01'});
    is $well->well_dna_quality->egel_pass, 1, 'DNA egel status is pass for A01';
    my $well6 = model->retrieve_well({ plate_name=>'HCL_DNA', well_name=>'A06'});
    is $well6->well_dna_quality->egel_pass, 0, 'DNA egel status is fail for A06';

    note("repeated plate update ok");
    $mech->get_ok('/user/dna_quality_update');
    ok $mech->submit_form(
        form_id => 'dna_quality_update',
        fields => {
            datafile => $example_ss_path,
            plate_name => 'HCL_DNA',
        },
        button  => 'update_dna_quality',
    ), 'dna egel pass data uploaded';
    $mech->content_contains('Uploaded dna quality information onto plate HCL_DNA');

}
=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

