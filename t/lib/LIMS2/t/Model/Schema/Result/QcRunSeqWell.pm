package LIMS2::t::Model::Schema::Result::QcRunSeqWell;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::QcRunSeqWell;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Schema/Result/QcRunSeqWell.pm - test class for LIMS2::Model::Schema::Result::QcRunSeqWell

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
    local $TODO = 'Test of LIMS2::Model::Schema::Result::QcRunSeqWell not implemented yet';
    ok(1, "Test of LIMS2::Model::Schema::Result::QcRunSeqWell");
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

