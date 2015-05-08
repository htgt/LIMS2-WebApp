package LIMS2::t::Model::Schema::Result::CrisprOffTargets;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Schema::Result::CrisprOffTargets;
use LIMS2::Model::DBConnect;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Schema/Result/CrisprOffTargets.pm - test class for LIMS2::Model::Schema::Result::CrisprOffTargets

=head1 DESCRIPTION

Test module structured for running under Test::Class

=cut

=head2 all_tests

Code to execute all tests

=cut

sub all_tests : Tests {
    my $user                 = 'lims2';
    my $connect_entry        = 'LIMS2_DB';
    my $rs_species           = 'Species';
    my $rs_crisprs           = 'Crispr';
    my $rs                   = 'CrisprOffTargets';
    my (%crisprs_record) = (
        'id'                  => 9999,
        'seq'                 => 'GCCCATTGACTCGGGACTTCTGG',
        'species_id'          => 'Alien',
        'crispr_loci_type_id' => 'Exonic',
        'comment'             => 'comment',
    );
    my (%species_record) = ( 'id' => 'Alien', );
    my %record = (
        'id'                   => 9999,
        'crispr_id'            => 9999,
        'off_target_crispr_id' => 200,
        'mismatches'           => 2,
    );

    note("Accessing the schema");
    ok( $ENV{$connect_entry} ne '', '$ENV{LIMS2_DB} has been set up' );
    my $schema = LIMS2::Model::DBConnect->connect( $connect_entry, $user );
    ok( $schema, 'LIMS2::Model::DBConnect connected to the database' );

    note("Obtain result set handles");
    my $resultset = $schema->resultset($rs);
    ok( $resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $species_resultset = $schema->resultset($rs_species);
    ok( $species_resultset, 'LIMS2::Model::DBConnect obtained result set' );
    my $crisprs_resultset = $schema->resultset($rs_crisprs);
    ok( $crisprs_resultset, 'LIMS2::Model::DBConnect obtained result set' );

    note("Cleanup before the tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';

    note("Generating reference data Species record");
    lives_ok { $species_resultset->find_or_create( \%species_record ) } 'Inserting new record';

    note("Generating reference data Crispr record");
    lives_ok { $crisprs_resultset->find_or_create( \%crisprs_record ) } 'Inserting new record';

    note("CRUD tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting any existing test records';
    lives_ok { $resultset->create( \%record ) } 'Inserting new record';
    my $stored = $resultset->search( \%record )->single();
    ok( $stored, 'Obtained record from the database' );
    my %inflated = $stored->get_columns();
    cmp_deeply( \%record, \%inflated, 'Verifying retrieved record matches inserted values' );
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';

    note("Teardown after the tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';
    lives_ok { $crisprs_resultset->search( \%crisprs_record )->delete() }
    'Deleting the existing test records';
}

## use critic

1;

__END__

