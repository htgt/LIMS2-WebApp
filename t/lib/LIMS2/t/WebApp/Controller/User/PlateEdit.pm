package LIMS2::t::WebApp::Controller::User::PlateEdit;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::PlateEdit;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/PlateEdit.pm - test class for LIMS2::WebApp::Controller::User::PlateEdit

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

sub all_tests  : Test(18)
{

    my $mech = mech();

    my $plate_without_children = model->retrieve_plate( { name => 'FFP0001' } );
    my $plate_with_children = model->retrieve_plate( { name => 'PCS00097_A' } );

    {
	note( "Visit plate edit page" );

	$mech->get_ok( '/user/view_plate?id=' . $plate_without_children->id );
	$mech->title_is('View Plate');
	$mech->content_like( qr/delete_plate_button/, '..has delete plate button');

	$mech->get_ok( '/user/view_plate?id=' . $plate_with_children->id );
	$mech->title_is('View Plate');
	$mech->content_unlike( qr/delete_plate_button/, '..has no delete plate button');
    }

    {
	note( "Test rename plate" );
	my $plate = model->retrieve_plate( { name => 'SEP0006' } );

	$mech->get_ok( '/user/rename_plate?id=' . $plate->id . '&name=' . $plate->name . '&new_name=' . $plate_with_children->name );
	$mech->base_like( qr{user/view_plate},'...moves to view_plates page');
	$mech->content_like( qr/Error encountered while renaming plate: .* already exists/, '...correct plate rename error message');

	$mech->get_ok( '/user/rename_plate?id=' . $plate->id . '&name=' . $plate->name . '&new_name=FOOBAR' );
	$mech->base_like( qr{user/view_plate},'...moves to view_plate page');
	$mech->content_like( qr/Renamed plate from SEP0006 to FOOBAR/, '...correct plate rename message');
    }

    {
	note( "Test plate delete" );

	$mech->get_ok( '/user/delete_plate?id=' . $plate_without_children->id . '&name=' . $plate_without_children->name );
	$mech->base_like( qr{user/browse_plates},'...moves to browse_plates page');
	$mech->content_like( qr/Deleted plate FFP0001/, '...correct plate delete message');

	$mech->get_ok( '/user/delete_plate?id=' . $plate_with_children->id . '&name=' . $plate_with_children->name );
	$mech->base_like( qr{user/view_plate},'...moves to view_plate page');
	$mech->content_like( qr/Error encountered while deleting plate: .* has child plates/, '...correct delete plate error message');
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

