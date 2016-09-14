package LIMS2::t::WebApp::Controller::User::Graph;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::Graph;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/Graph.pm - test class for LIMS2::WebApp::Controller::User::Graph

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

sub all_tests  : Test(12) {
    my $mech = mech();

    {
	note( "Test well relations" );

	$mech->get_ok( '/user/graph' );
	ok my $res = $mech->submit_form(
	    form_number => '1',
	    fields  => { plate_name => 'SEP0006', well_name => 'A01', graph_type => 'descendants' },
	    button => 'go',
	), 'submit well relation graph request';
	$mech->content_contains("<object", 'result page contains image object');
	my ($image_uri) = ( $mech->content =~ /<object data=\"([^\"]*)\"/);
	ok $image_uri, 'image uri found';
	$mech->get_ok($image_uri, 'image exists');
	$mech->content_contains('MOHSAQ0001_A_2_B04','graph contains well MOHSAQ0001_A_2_B04');
    }

    {
	note( "Test plate relations" );

	$mech->get_ok( '/user/graph' );
	ok my $res = $mech->submit_form(
	    form_number => '2',
	    fields  => { pr_plate_name => 'SEP0006', pr_graph_type => 'descendants' },
	    button => 'go',
	), 'submit plate relation graph request';
	$mech->content_contains("<object", 'result page contains image object');
	my ($image_uri) = ( $mech->content =~ /<object data=\"([^\"]*)\"/);
	ok $image_uri, 'image uri found';
	$mech->get_ok($image_uri, 'image exists');
	$mech->content_contains('SEPD0006_1','graph contains plate SEPD0006_1');
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

