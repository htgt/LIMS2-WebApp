package LIMS2::t::WebApp::Controller::User::PlateCopy;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::PlateCopy;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/PlateCopy.pm - test class for LIMS2::WebApp::Controller::User::PlateCopy

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

sub all_tests  : Test(27)
{

    my $mech = mech();

    {
	note( "Copy DNA plate interface" );
	$mech->get_ok( '/user/plate_from_copy' );
	$mech->title_is('Plate Copy');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_copy'), 'submit form with no "to" or "from" plate names';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_from_copy', '...stays on the same page';
	like $res->content, qr/Specify both \S+ plate name and \S+ plate name/, '... no to plate names specified';
    }

    {
	note( "What if only input plate is specified?" );
	$mech->get_ok( '/user/plate_from_copy' );
	$mech->title_is('Plate Copy');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_copy',
	    fields => {
		from_plate_name => 'MOHSAS60001_F',
	    }
	), 'submit form with no "from" plate name';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_from_copy', '...stays on the same page';
	like $res->content, qr/Specify both \S+ plate name and \S+ plate name/, '... no "to" plate name specified';
    }

    {
	note( "Copy a test plate through the web interface" );
	my $plate_data = test_data( 'dna_test_plate.yaml' );
	ok my $dna_plate = model->create_plate( $plate_data->{'dna_plate_create_params'} ),
	    'dna plate creation succeeded';
	$mech->get_ok( '/user/plate_from_copy' );
	$mech->title_is('Plate Copy');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_copy',
	    fields => {
		from_plate_name => 'DUMMY01',
		to_plate_name   => 'DUMMY01_1',
	    }
	), 'submit form with valid "from" and "to" plate names';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_from_copy', '...stays on the same page';
	like $res->content, qr/successfully/, '... plate copied successfully';

    }

    {
	note( "Copy a test plate through the web interface to an existing plate" );
	$mech->get_ok( '/user/plate_from_copy' );
	$mech->title_is('Plate Copy');
	ok my $res = $mech->submit_form(
	    form_id => 'plate_copy',
	    fields => {
		from_plate_name => 'DUMMY01',
		to_plate_name   => 'DUMMY01_1',
	    }
	), 'submit form with valid "from" and "to" plate names';

	ok $res->is_success, '...response is_success';
	is $res->base->path, '/user/plate_from_copy', '...stays on the same page';
	like $res->content, qr/already/, '... plate already exists in LIMS2';

    }

    {
	note( "Clean up newly created and copied plates" );

	lives_ok {
	    model->delete_plate( { name => 'DUMMY01_1' } )
	} 'delete plate DUMMY01_1';
	 lives_ok {
	    model->delete_plate( { name => 'DUMMY01' } )
	} 'delete plate DUMMY01';

    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

