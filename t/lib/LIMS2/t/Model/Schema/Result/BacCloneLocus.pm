package LIMS2::t::Model::Schema::Result::BacCloneLocus;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::BacCloneLocus;
use LIMS2::Model::DBConnect;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Schema/Result/BacCloneLocus.pm - test class for LIMS2::Model::Schema::Result::BacCloneLocus

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

sub all_tests : Test(34) {
    my $user           = 'lims2';
    my $connect_entry  = 'LIMS2_DB';
    my $rs             = 'BacCloneLocus';
    my $rs_assembly    = 'Assembly';
    my $rs_species     = 'Species';
    my $rs_bac_clone   = 'BacClone';
    my $rs_chromosomes = 'Chromosome';
    my $rs_bac_library = 'BacLibrary';
    my (%species_record) = ( 'id' => 'Alien', );
    my (%assembly_record) = (
        'id'         => 'NZB999',
        'species_id' => 'Alien',
    );
    my (%chromosome_record) = (
        'id'         => 9999,
        'species_id' => 'Alien',
        'name'       => 'Test',
    );
    my (%bac_library_record) = (
        'id'         => 'aaa',
        'species_id' => 'Alien',
    );
    my (%bac_clone_record) = (
        'id'             => 999999,
        'name'           => 'Test',
        'bac_library_id' => 'aaa',
    );
    my %record = (
        bac_clone_id => 999999,
        assembly_id  => 'NZB999',
        chr_start    => 99999990,
        chr_end      => 99999999,
        chr_id       => 9999,
    );

    note("Accessing the schema");
    ok( $ENV{$connect_entry} ne '', '$ENV{LIMS2_DB} has been set up' );
    my $schema = LIMS2::Model::DBConnect->connect( $connect_entry, $user );
    ok( $schema, 'LIMS2::Model::DBConnect connected to the database' );

    note("Obtain result set handles");
    my $resultset = $schema->resultset($rs);
    ok( $resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $bac_library_resultset = $schema->resultset($rs_bac_library);
    ok( $bac_library_resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $species_resultset = $schema->resultset($rs_species);
    ok( $species_resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $assembly_resultset = $schema->resultset($rs_assembly);
    ok( $assembly_resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $bac_clone_resultset = $schema->resultset($rs_bac_clone);
    ok( $bac_clone_resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $chromosome_resultset = $schema->resultset($rs_chromosomes);
    ok( $chromosome_resultset, 'LIMS2::Model::DBConnect obtained result set' );

    note("Cleanup before the tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';
    lives_ok { $bac_clone_resultset->search( \%bac_clone_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $bac_library_resultset->search( \%bac_library_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $assembly_resultset->search( \%assembly_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $chromosome_resultset->search( \%chromosome_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting the existing test records';

    note("Generating reference data Species record");
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $species_resultset->create( \%species_record ) } 'Inserting new record';

    note("Generating reference data Assembly record");
    lives_ok { $assembly_resultset->search( \%assembly_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $assembly_resultset->create( \%assembly_record ) } 'Inserting new record';

    note("Generating reference data BacLibrary record");
    lives_ok { $bac_library_resultset->search( \%bac_library_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $bac_library_resultset->create( \%bac_library_record ) } 'Inserting new record';

    note("Generating reference data Chromosome record");
    lives_ok { $chromosome_resultset->search( \%chromosome_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $chromosome_resultset->create( \%chromosome_record ) } 'Inserting new record';

    note("Generating reference data BacClone record");
    lives_ok { $bac_clone_resultset->search( \%bac_clone_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $bac_clone_resultset->create( \%bac_clone_record ) } 'Inserting new record';

    note("CRUD tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting any existing test records';
    lives_ok { $resultset->create( \%record ) } 'Inserting new record';
    my $stored = $resultset->search( \%record )->single();
    ok( $stored, 'Obtained record from the database' );
    my %inflated = $stored->get_columns();
    cmp_deeply( \%record, \%inflated, 'Verifying retrieved record matches inserted values' );

    note("Teardown after the tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';
    lives_ok { $bac_clone_resultset->search( \%bac_clone_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $bac_library_resultset->search( \%bac_library_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $assembly_resultset->search( \%assembly_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $chromosome_resultset->search( \%chromosome_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting the existing test records';

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

