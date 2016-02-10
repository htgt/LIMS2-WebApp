package LIMS2::t::WebApp::Controller::User::PlateUpload;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::PlateUpload;

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

sub all_tests  : Test(112)
{
    my $mech = mech();

    {   
	note( "set undef process type" );
	$mech->get_ok( '/user/plate_upload_step1' );
	$mech->title_is('Plate Upload');
	ok my $res = $mech->submit_form(
	    form_id => 'process_type_select',
	    fields  => { process_type => ''},
	), 'submit form with no process type selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step1', '...stays on the same page';
	like $res->content, qr/You must specify a process type/, '... no process type specified';
    }

    {   
	note( "set invalid process type" );
	$mech->get_ok( '/user/plate_upload_step1' );
	$mech->title_is('Plate Upload');
	ok my $res = $mech->submit_form(
	    form_id => 'process_type_select',
	    fields  => { process_type => 'foo'},
	), 'submit form with invalid process type selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... moves onto step 2';
	like $res->content, qr/is invalid: existing_process_type/, '...correct validation error';
    }
																				 {   
	note( "set process type to rearray" );
	$mech->get_ok( '/user/plate_upload_step1' );
	$mech->title_is('Plate Upload');
	ok my $res = $mech->submit_form(
	    form_id => 'process_type_select',
	    fields  => { process_type => 'rearray'},
	), 'submit form with rearray process type selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... moves onto step 2';
	like $res->content, qr/rearray/, '...process type set to rearray';
    }

    {   
	note( "set process type to first_electroporation" );
	$mech->get_ok( '/user/plate_upload_step1' );
	$mech->title_is('Plate Upload');
	ok my $res = $mech->submit_form(
	    form_id => 'process_type_select',
	    fields  => { process_type => 'first_electroporation'},
	), 'submit form with first_electroporation process type selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... moves onto step 2';
	like $res->content, qr/first_electroporation/, '...process type set to first_electroporation';
	like $res->content, qr/Cell Line/, '...has cell_line field';
    }

    {
	note( "2w_gateway process type form check" );
	$mech->get_ok( '/user/plate_upload_step2?process_type=2w_gateway' );
	$mech->title_is('Plate Upload 2');
	$mech->text_contains('Backbone (Final)', '...have Backbone field');
	$mech->text_contains('Cassette (Final)', '...have Cassette field');

    }

    {
	note( "No well data file set" );
	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	$mech->text_contains('Cell Line', '...have Cell Line field');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name   => 'EPTEST',
		process_type => 'first_electroporation',
		plate_type   => 'EP',
	    },
	    button  => 'create_plate'
	), 'submit form without file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/No csv file with well data specified/, '...throws error saying no csv file specified';
    }

    {
	note( "No plate_name set" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print('Test File');

	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	$mech->text_contains('Cell Line', '...have Cell Line field');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_type => 'EP',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form without plate name';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/Must specify a plate name/, '...throws error must specify plate name';
    }

    {   
	note( "No plate_type set" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print('Test File');

	$mech->get_ok( '/user/plate_upload_step2?process_type=rearray' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'TEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form without plate type';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/Must specify a plate type/, '...throws error must specify plate type';
    }

    {
	note( "Invalid well data csv file" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);

	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'EPTEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with invalid well data csv file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/Error encountered while creating plate: No data in csv file/
	    , '...throws error invalid well data csv file';
    }

    {   
	note( "No well data" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print('Test File');
	$test_file->seek( 0, 0 );
	#my $test_file_content = "well_name,parent_plate,parent_well\n" . "A01,MOHFAQ001_A_2,A01";

	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'EPTEST',
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
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'EPTEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with well data file with invalid well data';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/well_name, is invalid: well_name/
	    , '...throws error parameter validation failed for well_name';
    }

    {   
	note( "Invalid parent well" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well,cell_line\n"
			  . "A01,MOHFAZ001_A_2,A01,cell_line_foo");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'EPTEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with well data file with invalid parent well data';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/Error encountered while creating plate: Can not find parent well MOHFAZ/
	    , '...throws error can not find parent well';
    }

    {   
	note( "Invalid virtual plate" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well\n"
			  . "A01,PCS00148_A,F02");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=rearray' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'VTEST',
		datafile   => $test_file->filename,
		is_virtual => 1,
		plate_type => 'EP',
	    },
	    button  => 'create_plate'
	), 'submit virtual plate form with valid well data file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content, qr/Error encountered while creating plate: Plate type \(EP\) and process/
	    , '...throws error invalid combination of plate type and process for virtual plate';
    }

    {   
	note( "Valid intermediate virtual plate" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well\n"
			  . "A01,PCS00148_A,F02");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=rearray' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'VTEST',
		datafile   => $test_file->filename,
		is_virtual => 1,
        source_dna => 'BOB',
		plate_type => 'INT',
	    },
	    button  => 'create_plate'
	), 'submit virtual plate form with valid well data file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/view_plate', '... moves to plate view page';
	like $res->content, qr/Created new plate VTEST/ , '...page has create new plate message';
    }


    {
	note( "Successful plate create" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well,cell_line\n"
			  . "A01,MOHFAQ0001_A_2,A01,oct4:puro iCre/iFlpO #11");
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'EPTEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with valid well data file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/view_plate', '... moves to plate view page';
	like $res->content, qr/Created new plate EPTEST/ , '...page has create new plate message';
    }

    {
	note( "Delete newly created plate" );

	lives_ok {
	    model->delete_plate( { name => 'EPTEST' } )
	} 'delete plate';
    }

    {   
	note( "Unsuccessful XEP multi pool plate create" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well\n"
			  . "A01,FEPD0006_1,A01\n"
			  . "A01,FEPD0006_2,A02\n"
			  . "A01,FEPD0006_1,C06"
		      );
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=xep_pool' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'XEP_TESTA',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with valid well data file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
	like $res->content,
    qr/Error encountered while creating plate: Wells from different plates cannot be pooled to the same output well: Already seen: FEPD0006_1 and was not expecting: FEPD0006_2/
	    , '...throws error different parent plates not allowed';
    }

    {
	note( "Successful XEP multi pool plate create" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well\n"
			  . "A01,FEPD0006_1,A01\n"
			  . "A01,FEPD0006_1,A02\n"
			  . "A01,FEPD0006_1,C06"
		      );
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=xep_pool' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'XEP_TEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with valid well data file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/view_plate', '... moves to plate view page';
	like $res->content, qr/Created new plate XEP_TEST/ , '...page has create new plate message';
    }

    {   
	note( "Delete XEP_TEST" );

	lives_ok {
	    model->delete_plate( { name => 'XEP_TEST' } )
	} 'delete plate';
    }

    {
	note( "Successful XEP one-to-one mapping plate create" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,parent_plate,parent_well\n"
			  . "A01,FEPD0006_1,A01\n"
			  . "A02,FEPD0006_1,A02\n"
			  . "A03,FEPD0006_1,C06"
		      );
	$test_file->seek( 0, 0 );

	$mech->get_ok( '/user/plate_upload_step2?process_type=xep_pool' );
	$mech->title_is('Plate Upload 2');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_create',
	    fields  => {
		plate_name => 'XEP_TEST1',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with valid well data file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/view_plate', '... moves to plate view page';
	like $res->content, qr/Created new plate XEP_TEST1/ , '...page has create new plate message';
    }

    {
	note( "Delete XEP_TEST1" );

	lives_ok {
	    model->delete_plate( { name => 'XEP_TEST1' } )
	} 'delete plate';
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

