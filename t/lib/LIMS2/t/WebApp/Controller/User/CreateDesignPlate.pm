package LIMS2::t::WebApp::Controller::User::CreateDesignPlate;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::CreateDesignPlate;

use LIMS2::Test;
use File::Temp ':seekable';

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/PlateUpload.pm - test class for LIMS2::WebApp::Controller::User::PlateUpload

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

=head2 all_tests

Code to execute all tests

=cut

sub all_tests  : Test(20)
{
    my $mech = mech();
    $mech->get_ok('/user/select_species?species=Mouse');
    {        
	note( "No design plate data file set" );
	$mech->get_ok( '/user/create_design_plate' );
	$mech->title_is('Create Design Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'design_plate_create',
	    fields  => {
		plate_name   => 'DESIGN_TEST',
	    },
	    button  => 'create_plate'
	), 'submit form without file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_design_plate', '... stays on same page';
	like $res->content, qr/No csv file containing design plate data uploaded/, '...throws error saying no csv file specified';
    }

    {
	note( "No plate_name set" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print('Test File');

	$mech->get_ok( '/user/create_design_plate' );
	$mech->title_is('Create Design Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'design_plate_create',
	    fields  => {
			datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form without plate name';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_design_plate', '... stays on same page';
	like $res->content, qr/Please enter a plate name/, '...throws error must specify plate name';
    }

=head
    {
	note( "Invalid well data csv file" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);

	$mech->get_ok( '/user/create_design_plate' );
	$mech->title_is('Create Design Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'design_plate_create',
	    fields  => {
		plate_name => 'DESIGN_TEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with invalid well data csv file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_design_plate', '... stays on same page';
	like $res->content, qr/Error encountered while creating plate: No data in csv file/
	    , '...throws error invalid well data csv file';
    }
=cut
=head
    {   
	note( "No well data" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print('Test File');
	$test_file->seek( 0, 0 );
	#my $test_file_content = "well_name,parent_plate,parent_well\n" . "A01,MOHFAQ001_A_2,A01";

	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'design_plate_create',
	    fields  => {
		plate_name => 'DESIGN_TEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with well data file with no well data';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/Error encountered while creating plate: No data in csv file/
	    , '...throws error no well data in file';
    }

    {
	note( "Invalid well data" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well,cell_line\n"
			  . "BLAH,MOHFAQ001_A_2,A01,cell_line_foo");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'design_plate_create',
	    fields  => {
		plate_name => 'DESIGN_TEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with well data file with invalid well data';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/well_name, is invalid: well_name/
	    , '...throws error parameter validation failed for well_name';
    }
=cut
    {
	note( "Successful plate create" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,design_id\n"
			  . "A01,372441");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/create_design_plate' );
	$mech->title_is('Create Design Plate');

	ok my $res = $mech->submit_form(
	    form_id => 'design_plate_create',
	    fields  => {
		plate_name => 'DESIGN_TEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with valid well data file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_design_plate', '... moves to plate view page';
	like $res->content, qr/Successful design plate creation/ , '...page has create new plate message';
    }

    {
	note( "Delete newly created plate" );

	lives_ok {
	    model->delete_plate( { name => 'DESIGN_TEST' } )
	} 'delete plate';
    }

}

## use critic

1;

__END__

