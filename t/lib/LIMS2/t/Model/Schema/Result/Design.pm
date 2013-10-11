package LIMS2::t::Model::Schema::Result::Design;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::Design;
use LIMS2::Model::DBConnect;
use DateTime;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Schema/Result/Design.pm - test class for LIMS2::Model::Schema::Result::Design

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

sub all_tests : Tests {
    my $user           = 'lims2';
    my $connect_entry  = 'LIMS2_DB';
    my $rs_user        = 'User';
    my $rs_design_type = 'DesignType';
    my $rs_species     = 'Species';
    my $rs             = 'Design';
    my $now            = DateTime->now();
    my (%species_record)   = ( 'id' => 'Alien', );
    my %design_type_record = ( 'id' => 'alien design type', );
    my %user_record        = (
        'id'       => 990,
        'name'     => 'alien_user',
        'password' => 'secret',
        active     => 1,
    );
    my %record = (
        'id'                      => 99999,
        'name'                    => 'EUALIEN',
        'created_by'              => 990,
        'design_type_id'          => 'alien design type',
        'phase'                   => 0,
        'validated_by_annotation' => 'not done',
        'target_transcript'       => 'ENSMUST00000085065',
        'species_id'              => 'Alien',
        'design_parameters'       => 'design_parameters',
        'cassette_first'          => 1,
    );

    note("Accessing the schema");
    ok( $ENV{$connect_entry} ne '', '$ENV{LIMS2_DB} has been set up' );
    my $schema = LIMS2::Model::DBConnect->connect( $connect_entry, $user );
    ok( $schema, 'LIMS2::Model::DBConnect connected to the database' );

    note("Obtain result set handles");
    my $resultset = $schema->resultset($rs);
    ok( $resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $user_resultset = $schema->resultset($rs_user);
    ok( $user_resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $design_type_resultset = $schema->resultset($rs_design_type);
    ok( $design_type_resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $species_resultset = $schema->resultset($rs_species);
    ok( $species_resultset, 'LIMS2::Model::DBConnect obtained result set' );

    note("Cleanup before the tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';
    lives_ok { $user_resultset->search( \%user_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $design_type_resultset->search( \%design_type_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting the existing test records';

    note("Generating reference data Species record");
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $species_resultset->create( \%species_record ) } 'Inserting new record';

    note("Generating reference data User record");
    lives_ok { $user_resultset->search( \%user_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $user_resultset->create( \%user_record ) } 'Inserting new record';

    note("Generating reference data DesignType record");
    lives_ok { $design_type_resultset->search( \%design_type_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $design_type_resultset->create( \%design_type_record ) } 'Inserting new record';

    note("CRUD tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting any existing test records';
    lives_ok { $resultset->create( { %record, 'created_at' => $now } ) } 'Inserting new record';
    my $stored = $resultset->search( \%record )->single();
    ok( $stored, 'Obtained record from the database' );
    my %inflated = $stored->get_columns();
    cmp_deeply(
        \%inflated,
        { %record, 'created_at' => ignore() },
        'Verifying retrieved record matches inserted values'
    );
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';

    note("Teardown after the tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';
    lives_ok { $user_resultset->search( \%user_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $design_type_resultset->search( \%design_type_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting the existing test records';
}

## use critic

1;

__END__

