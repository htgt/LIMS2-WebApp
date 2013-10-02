package LIMS2::t::Model::Util::QCTemplates;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::QCTemplates qw( create_qc_template_from_wells );
use LIMS2::Test;
use Try::Tiny;
use IO::File;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/QCTemplates.pm - test class for LIMS2::Model::Util::QCTemplates

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

sub all_tests  : Test(1) {
    local $TODO = 'Test of LIMS2::Model::Util::QCTemplates not implemented yet';
    ok(1, "Test of LIMS2::Model::Util::QCTemplates");
}

=head1 AUTHOR

Sajith Perera

=cut

## use critic

1;

__END__

