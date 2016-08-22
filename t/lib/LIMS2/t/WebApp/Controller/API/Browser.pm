package LIMS2::t::WebApp::Controller::API::Browser;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::API::Browser;

use LIMS2::Test;
use File::Temp ':seekable';
use JSON;

use strict;

#
#
# No corresponding .t file
#
#



## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/API/Browser.pm - test class for LIMS2::WebApp::Controller::API::Browser

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

sub all_tests  : Test()
{
    my $mech = mech();


    my $species = 'Mouse';

    note( 'Testing Crispr REST API' );

    $mech->get_ok('/api/crispr/browse?'
        . 'assembly_id=' . $assembly_id
        . 'chr_id=' . $chromosome_id
        . 'start=' . $start_coord
        . 'end=' . $end_coord ,
		{'content-type' => 'application/json'} );

    ok my $json = decode_json($mech->content), 'can decode json response';

}

=head1 AUTHOR

D J Parry-Smith

=cut

## use critic

1;

__END__

