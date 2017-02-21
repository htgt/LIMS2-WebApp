package LIMS2::t::WebApp::Controller::Admin;

use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::Admin;

use LIMS2::Test model => { classname => __PACKAGE__ };

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/Admin.pm - test class for LIMS2::WebApp::Controller::Admin

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
use Smart::Comments;
use Data::Dumper;

sub all_tests  : Test(104) {
    ok(1, "Test of LIMS2::WebApp::Controller::Admin");

    my $mech = LIMS2::Test::mech();

    note( "Tests for Announcements" );

    my $default = {
    	message 			=> "Message test",
    	expiry_date 		=> "01/01/2050",
    	priority 			=> "normal",
    	webapp 				=> "LIMS2",
    	content_to_find 	=> "Message successfully created",
    	data_type 			=> "valid",
    	valid 				=> 0,
    };

    {
    	note( "###" );
    	note( "Valid data submission" );

    	my $changes->{valid} = 1;
	    _variable_submission($mech, $default, $changes);

	    note( "successful deletion");
	    $mech->content_contains('Message test');
	    ok my $res = $mech->submit_form(
	    	form_id 	=> 'announcement_form',
	    	button 		=> 'delete_message_button',
	    );
	    $mech->content_contains('Message successfully deleted');
	}

	{
		note( "###" );
		note( "Invalid year submission - 1999" );
		my $changes;
		$changes->{expiry_date} = '01/01/1999';
		$changes->{data_type} = 'invalid year';
		$changes->{content_to_find} = 'Please enter an expiry date which is in the future';
		_variable_submission($mech, $default, $changes);
	}

	{
		note( "###" );
		note( "Invalid year submission - 2999" );
		my $changes;
		$changes->{expiry_date} = '01/01/2999';
		$changes->{data_type} = 'invalid year';
		$changes->{content_to_find} = 'Please enter an expiry date which is no more than 100 years in the future';
		_variable_submission($mech, $default, $changes);
	}

	{
		note( "###" );
		note( "Invalid month submission - 13" );
		my $changes;
		$changes->{expiry_date} = '01/13/2050';
		$changes->{data_type} = 'invalid month';
		$changes->{content_to_find} = 'Error: please check the date is correct';
		_variable_submission($mech, $default, $changes);
	}

	{
		note( "###" );
		note( "Invalid month submission - 0" );
		my $changes;
		$changes->{expiry_date} = '01/0/2050';
		$changes->{data_type} = 'invalid month';
		$changes->{content_to_find} = 'Error: please check the date is correct';
		_variable_submission($mech, $default, $changes);
	}

	{
		note( "###" );
		note( "Invalid day submission - 0" );
		my $changes;
		$changes->{expiry_date} = '0/01/2050';
		$changes->{data_type} = 'invalid day';
		$changes->{content_to_find} = 'Error: please check the date is correct';
		_variable_submission($mech, $default, $changes);
	}

	{
		note( "###" );
		note( "Invalid day submission - 35" );
		my $changes;
		$changes->{expiry_date} = '35/01/2050';
		$changes->{data_type} = 'invalid day';
		$changes->{content_to_find} = 'Error: please check the date is correct';
		_variable_submission($mech, $default, $changes);
	}

	{
		note( "###" );
		note( "valid but different priority submission - high" );
		my $changes;
		$changes->{priority} = 'high';
		$changes->{valid} = 1;
		_variable_submission($mech, $default, $changes);

		note( "successful deletion");
	    $mech->content_contains('Message test');
	    ok my $res = $mech->submit_form(
	    	form_id 	=> 'announcement_form',
	    	button 		=> 'delete_message_button',
	    );
	    $mech->content_contains('Message successfully deleted');
	}

	{
		note( "###" );
		note( "valid but different priority submission - low" );
		my $changes;
		$changes->{priority} = 'low';
		$changes->{valid} = 1;
		_variable_submission($mech, $default, $changes);

		note( "successful deletion");
	    $mech->content_contains('Message test');
	    ok my $res = $mech->submit_form(
	    	form_id 	=> 'announcement_form',
	    	button 		=> 'delete_message_button',
	    );
	    $mech->content_contains('Message successfully deleted');
	}

	{
		note( "###" );
		note( "valid but different webapp submission - HTGT" );
		my $changes;
		$changes->{webapp} = 'HTGT';
		$changes->{valid} = 1;
		_variable_submission($mech, $default, $changes);

		note( "successful deletion");
	    $mech->content_contains('Message test');
	    ok my $res = $mech->submit_form(
	    	form_id 	=> 'announcement_form',
	    	button 		=> 'delete_message_button',
	    );
	    $mech->content_contains('Message successfully deleted');
	}

	{
		note( "###" );
		note( "valid but different webapp submission - WGE" );
		my $changes;
		$changes->{webapp} = 'WGE';
		$changes->{valid} = 1;
		_variable_submission($mech, $default, $changes);

		note( "successful deletion");
	    $mech->content_contains('Message test');
	    ok my $res = $mech->submit_form(
	    	form_id 	=> 'announcement_form',
	    	button 		=> 'delete_message_button',
	    );
	    $mech->content_contains('Message successfully deleted');
	}

}

sub _submit_message {
	my ($mech, $params) = @_;

	$mech->get_ok( '/admin/announcements' );
	$mech->title_is( 'LIMS2 - Announcements' );

	note( "Create announcement" );

    $mech->get_ok( '/admin/announcements/create_announcement' );
    $mech->title_is( 'LIMS2 - Create Announcement' );

    ok my $res = $mech->submit_form(
    	form_id 	=> 'create_announcement_form',
    	fields 		=> {
    		message  		=> $params->{message},
    		expiry_date 	=> $params->{expiry_date},
    		priority 		=> $params->{priority},
    		webapp 			=> $params->{webapp},
    	},
    	button 		=> 'create_announcement',
    ), "Submit form with $params->{data_type} data";

    ok $res->is_success, '...response is success';

    if ($params->{valid} == 1) {
    	$mech->base_like( qr{/admin/announcements} );
    	note($params->{valid});
    }
    else {
    	$mech->base_like( qr{/admin/announcements/create_announcement} );
    	note($params->{valid});
    }

    $mech->content_contains("$params->{content_to_find}");

    return;

}

sub _variable_submission {
	my ($mech, $params, $changes) = @_;
	my $copy = { %$params };

	while (my ($key, $value) = each %{$changes}) {
		$copy->{$key} = $value;
	}

	_submit_message($mech, $copy);

	return;

}

=head1 AUTHOR

Josh Kent

=cut

## use critic

1;

__END__

