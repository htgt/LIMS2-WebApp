package LIMS2::t::WebApp::Controller::User::RecombinaseUpload;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::RecombinaseUpload;

use LIMS2::Test;
use File::Temp ':seekable';

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/RecombinaseUpload.pm - test class for LIMS2::WebApp::Controller::User::RecombinaseUpload

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

sub all_tests  : Test(18)
{
    my $mech = mech();

    {   
	note( "set no data" );
	$mech->get_ok( '/user/recombinase_upload' );
	$mech->title_is('Add Recombinase');
	ok my $res = $mech->submit_form(
	    form_id => 'recombinase_form',
	    fields  => { plate_name => '', well_name => '', recombinase => ''},
	), 'submit form with no data selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/recombinase_upload', '...stays on the same page';
	like $res->content, qr/Data must be specified for all three fields; Plate Name, Well Name and Recombinase/, '... no data specified';
    }

    {   
	note( "set valid data" );
	$mech->get_ok( '/user/recombinase_upload' );
	$mech->title_is('Add Recombinase');
	ok my $res = $mech->submit_form(
	    form_id => 'recombinase_form',
	    fields  => { plate_name => 'FEPD0006_1', well_name => 'A01', recombinase => 'Dre'},
	), 'submit form with no data selected';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/recombinase_upload', '...stays on the same page';
	like $res->content, qr/Add Dre recombinase for well A01 on plate FEPD0006_1/, '... no data specified';
    }

    {   
	note( "Invalid well data csv file" );

	$mech->get_ok( '/user/recombinase_upload' );
	$mech->title_is('Add Recombinase');
	ok my $res = $mech->submit_form(
	    form_id => 'recombinase_file_upload',
	    fields  => {
		datafile   => ''
	    },
	    button  => 'upload'
	), 'submit form with invalid well data csv file';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/recombinase_upload', '... stays on same page';
	like $res->content, qr/No csv file with recombinase data specified/
	    , '...throws error invalid recombinase data csv file';
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

