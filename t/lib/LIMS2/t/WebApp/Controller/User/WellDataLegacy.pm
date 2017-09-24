package LIMS2::t::WebApp::Controller::User::WellDataLegacy;
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

sub all_tests  : Test(30)
{
    my $mech = mech();

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

