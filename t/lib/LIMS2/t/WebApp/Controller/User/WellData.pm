package LIMS2::t::WebApp::Controller::User::WellData;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::WellData;

use LIMS2::Test;
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

sub all_tests  : Test(67)
{

    my $mech = mech();

    {
	note( "No well data file set" );
	$mech->get_ok( '/user/dna_status_update' );
	$mech->title_is('DNA Status Update');
	ok my $res = $mech->submit_form(
	    form_id => 'dna_status_update',
	    fields  => {
		plate_name => 'MOHFAQ0001_A_2',
	    },
	    button  => 'update_dna_status'
	), 'submit form without file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/dna_status_update', '... stays on same page';
	like $res->content, qr/No csv file with dna status data specified/, '...throws error saying no csv file specified';
    }

    {
	note( "No plate_name set" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print('Test File');

	$mech->get_ok( '/user/dna_status_update' );
	$mech->title_is('DNA Status Update');
	ok my $res = $mech->submit_form(
	    form_id => 'dna_status_update',
	    fields  => {
		datafile   => $test_file->filename
	    },
	    button  => 'update_dna_status'
	), 'submit form without plate name';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/dna_status_update', '... stays on same page';
	like $res->content, qr/You must specify a plate name/, '...throws error must specify plate name';
    }

    {
	note( "Invalid csv data" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,dna_status_result\n"
			  . "BLAH,pass");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/dna_status_update' );
	$mech->title_is('DNA Status Update');
	ok my $res = $mech->submit_form(
	    form_id => 'dna_status_update',
	    fields  => {
		plate_name => 'MOHFAQ0001_A_2',
		datafile   => $test_file->filename
	    },
	    button  => 'update_dna_status'
	), 'submit form with well data file with invalid well data';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/dna_status_update', '... stays on same page';
	like $res->content, qr/Parameter validation failed\s+well_name/
	    , '...throws error parameter validation failed for well_name';
    }

    {
	note( "Successful creation of dna status values" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,dna_status_result,comments\n"
			  . "D02,pass,this is a comment");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/dna_status_update' );
	$mech->title_is('DNA Status Update');
	ok my $res = $mech->submit_form(
	    form_id => 'dna_status_update',
	    fields  => {
		plate_name => 'MOHFAQ0001_A_2',
		datafile   => $test_file->filename
	    },
	    button  => 'update_dna_status'
	), 'submit form with valid parameters';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/dna_status_update', '... stays on same page';
	like $res->content, qr/Uploaded dna status information onto plate MOHFAQ0001_A_2/ ,
	    '...page has success message';

	my $dna_status;
	lives_ok {
	    $dna_status = model->retrieve_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'D02' } );
	} 'retrieve newly created dna status';
	is $dna_status->pass, 1, 'has correct pass value';
	is $dna_status->comment_text, 'this is a comment', 'has correct comment';
    }

    {
	note( "Delete newly created dna status" );

	lives_ok {
	    model->delete_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'D02' } )
	} 'delete dna status data';
    }

    {
	note( 'Test uploading of empty wells not represented in LIMS2' );

	my $plate_data = test_data( 'dna_status.yaml' );
	ok my $dna_plate = model->create_plate( $plate_data->{'dna_plate_create_params'} ),
	    'dna plate creation succeeded';
	my $dna_status_update = model->create_well_dna_status ( $plate_data->{'create_well_dna_status_params'} );
	ok  (! $dna_status_update ,
	    'dna status update for empty (non-existent LIMS2) well was handled correctly');
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,dna_status_result,comments\n"
			  . "A03,pass,this is a comment");
	$test_file->seek( 0, 0 );
	$mech->get_ok('/user/dna_status_update');
	$mech->title_is('DNA Status Update');
	ok my $res = $mech->submit_form(
	    form_id => 'dna_status_update',
	    fields  => {
		plate_name => 'DUMMY01',
		datafile   => $test_file->filename
	    },
	    button  => 'update_dna_status'
	), 'submit form with valid parameters';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/dna_status_update', '... stays on same page';
	like $res->content, qr/Uploaded dna status information onto plate DUMMY01/ ,
	    '...page has success message';
	like $res->content, qr/A03 - well not available in LIMS2/,
	    '...well A03 not available in LIMS2 -- reported correctly';

    }

    {
	note( "set no data" );
	$mech->get_ok( '/user/update_colony_picks_step_1' );
	$mech->title_is('Colony Counts');
	ok my $res = $mech->submit_form(
	    form_id => 'colony_count_form',
	    fields  => { plate_name => '', well_name => ''},
	), 'submit form with no data selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/update_colony_picks_step_1', '...stays on the same page';
	like $res->content, qr/id_or_name, is missing/, '... no data specified';
    }

    {
	note( "select invalid plate type" );
	$mech->get_ok( '/user/update_colony_picks_step_1' );
	$mech->title_is('Colony Counts');
	ok my $res = $mech->submit_form(
	    form_id => 'colony_count_form',
	    fields  => { plate_name => 'FEPD0006_1', well_name => 'A01'},
	), 'submit form with no data selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/update_colony_picks_step_1', '...stays on the same page';
	like $res->content, qr/invalid plate type; can only add colony data to EP, SEP and XEP plates/, '... invalid plate type';
    }

    {
	note( "set valid plate type" );
	$mech->get_ok( '/user/update_colony_picks_step_1' );
	$mech->title_is('Colony Counts');
	ok my $res = $mech->submit_form(
	    form_id => 'colony_count_form',
	    fields  => { plate_name => 'FEP0006', well_name => 'A01'},
	), 'submit form with no data selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/update_colony_picks_step_2', '...move to step 2';
	like $res->content, qr/total_colonies/, '... valid plate type';
    }

    {
	note( "set valid plate type" );
	$mech->get_ok( '/user/update_colony_picks_step_2' );
	$mech->title_is('Colony Counts');
	ok my $res = $mech->submit_form(
	    form_id => 'colony_count_form',
	    fields  => { plate_name => 'FEP0006', well_name => 'A01', total_colonies => 30},
	), 'submit form with no data selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/update_colony_picks_step_1', '...move to step 1';
	like $res->content, qr/Successfully added colony picks/, '... valid plate type';
    }

    {
	note( "Invalid colony count data csv file" );

	$mech->get_ok( '/user/update_colony_picks_step_1' );
	$mech->title_is('Colony Counts');
	ok my $res = $mech->submit_form(
	    form_id => 'colony_count_upload',
	    fields  => {
		datafile   => ''
	    },
	    button  => 'upload'
	), 'submit form with invalid colony count data csv file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/update_colony_picks_step_1', '... stays on same page';
	like $res->content, qr/No csv file with well colony counts data specified/
	    , '...throws error invalid colony count data csv file';
    }


}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

