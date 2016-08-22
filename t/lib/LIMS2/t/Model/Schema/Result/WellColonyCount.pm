package LIMS2::t::Model::Schema::Result::WellColonyCount;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::WellColonyCount;
use LIMS2::Model::DBConnect;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Schema/Result/WellColonyCount.pm - test class for LIMS2::Model::Schema::Result::WellColonyCount

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN {

    # compile time requirements
    #{REQUIRE_PARENT}
}

=head2 before

Code to run before every test

=cut

sub before : Test(setup) {

    #diag("running before test");
}

=head2 after

Code to run after every test

=cut

sub after : Test(teardown) {

    #diag("running after test");
}

=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup) {

    #diag("running before all tests");
}

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown : Test(shutdown) {

    #diag("running after all tests");
}

=head2 all_tests

Code to execute all tests

=cut

sub all_tests : Test(1) {
    my $user          = 'lims2';
    my $connect_entry = 'LIMS2_DB';
    my $rs            = 'WellColonyCount';
    my %record        = ();

    ok( 1, "Test of LIMS2::Model::Schema::Result::WellColonyCount" );

    #note("Accessing the schema");
    #ok($ENV{$connect_entry} ne '', '$ENV{LIMS2_DB} has been set up');
    #my $schema = LIMS2::Model::DBConnect->connect( $connect_entry, $user );
    #ok ($schema, 'LIMS2::Model::DBConnect connected to the database');
    #my $resultset = $schema->resultset( $rs );
    #ok ($resultset, 'LIMS2::Model::DBConnect obtained result set');

    #note("CRUD tests");
    #lives_ok { $resultset->search(\%record)->delete() } 'Deleting any existing test records';
    #lives_ok { $resultset->create(\%record) } 'Inserting new record';
    #my $stored = $resultset->search(\%record)->single();
    #ok ($stored, 'Obtained record from the database');
    #my %inflated = $stored->get_columns();
    #cmp_deeply(\%record, \%inflated, 'Verifying retrieved record matches inserted values');
    #lives_ok { $resultset->search(\%record)->delete() } 'Deleting the existing test records';

}

## use critic

1;

__END__

