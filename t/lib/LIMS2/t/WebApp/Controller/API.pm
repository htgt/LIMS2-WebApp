package LIMS2::t::WebApp::Controller::API;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::API;
use Sub::Exporter -setup => {
    exports => [
        qw(
            construct_post
        )
    ]
};
use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/API.pm - test class for LIMS2::WebApp::Controller::API

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

sub all_tests  : Test(1)
{
    ok(1, "Test of LIMS2::WebApp::Controller::API");
}

sub construct_post
{
    my $url = shift;
    my $data = shift;
 
    my $req = HTTP::Request->new( "POST" => $url );
    $req->content_type( 'application/json' );
    if ($data) {
        $req->content_length(
            do { use bytes; length( $data ) }
        );
        $req->content( $data );
    }
    return $req;
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

