package LIMS2::t::WebApp::Controller::User::CreateDesignPlate;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::CreateDesignPlate;

use LIMS2::Test model => { classname => __PACKAGE__ }, 'mech';
use File::Temp ':seekable';

use strict;

## no critic

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $OFF );
};




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

    {
	note( "Empty csv file" );
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
	), 'submit form with empty csv file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_design_plate', '... stays on same page';
	like $res->content, qr/Invalid file/
	    , '...throws error invalid csv file';
    }

    {
	note( "Successful plate create" );
$DB::single=1;
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
	$test_file->print("well_name,design_id\n"
			  . "A01,10000841");
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

