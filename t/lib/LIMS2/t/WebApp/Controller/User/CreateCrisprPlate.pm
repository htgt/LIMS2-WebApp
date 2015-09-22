package LIMS2::t::WebApp::Controller::User::CreateCrisprPlate;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::CreateCrisprPlate;
$DB::single=1;
use LIMS2::Test model => { classname => __PACKAGE__ };
use File::Temp ':seekable';

use strict;

## no critic

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
};

my $mech = LIMS2::Test::mech();

sub all_tests  : Test(56)
{
    {
	note( "Empty file" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print(",,");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
        append_type => 't7-barry',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with empty csv file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/Invalid file. The file must be a csv containing the headers "well_name" and "crispr_id"/
	    , '...throws error empty file';
    }

    {
	note( "Invalid append" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,crispr_id\n"
                    . "A01,226375");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with invalid append';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/Error creating plate: No appends provided/
	    , '...throws error missing append';
    }

    {
	note( "Missing plate name" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,crispr_id\n"
                    . "A01,226375");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
        append_type => 't7-barry',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form without a plate name';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/Please enter a plate name/
	    , '...missing plate name';
    }

    {
	note( "Missing file" );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
        append_type => 't7-barry',
	    },
	    button  => 'create_plate'
	), 'submit form with a missing csv';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/No csv file containing crispr plate data uploaded/
	    , '...missing csv file';
    }


    {
	note( "Successful run" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,crispr_id\n"
                    . "A01,226375");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
        append_type => 't7-barry',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with everything correct';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/Successful/
	    , '...successful creation';
    }

    {
	note( "Duplicate run" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,crispr_id\n"
                    . "A01,226375");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');
	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
        append_type => 't7-barry',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit duplicate from without deleting the previous';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/already exists/
	    , '...duplicate found';
    }
    {
	note( "Delete newly created plate" );

	lives_ok {
	    model->delete_plate( { name => 'CRISPR_TEST' } )
	} 'delete plate';
    }

    {
	note( "Invalid LIMS2 crispr run" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,crispr_id\n"
                    . "A01,511654476");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');

	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
        append_type => 't7-barry',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with WGE id as LIMS2 crispr';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/Crispr entity not found/
	    , '...Incorrect lims2 crispr';
    }

    {
	note( "Invalid WGE run" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,crispr_id\n"
                    . "A01,226375");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');

    my $form_mech = $mech->current_form();
    $form_mech->find_input('wge')->check();

	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
        append_type => 't7-barry',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with invalid WGE crispr';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/Crispr entity not found/
	    , '...Incorrect wge';
    }

    {
	note( "Successful WGE run" );
	my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,crispr_id\n"
                    . "A01,511654476");
    $test_file->seek( 0, 0 );
	$mech->get_ok( '/user/create_crispr_plate' );
	$mech->title_is('Create Crispr Plate');

    my $form_mech = $mech->current_form();
    $form_mech->find_input('wge')->check();

	ok my $res = $mech->submit_form(
	    form_id => 'crispr_plate_create',
	    fields  => {
		plate_name => 'CRISPR_TEST',
        append_type => 't7-barry',
		datafile   => $test_file->filename
	    },
	    button  => 'create_plate'
	), 'submit form with WGE ticked';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/create_crispr_plate', '... stays on same page';
	like $res->content, qr/Successful/
	    , '...successful creation';
    }
    {
	note( "Delete newly created plate" );

	lives_ok {
	    model->delete_plate( { name => 'CRISPR_TEST' } )
	} 'delete plate';
    }

}

## use critic

1;

__END__

