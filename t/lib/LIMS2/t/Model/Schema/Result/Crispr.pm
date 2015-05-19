package LIMS2::t::Model::Schema::Result::Crispr;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::DBConnect;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Schema/Result/Crispr.pm - test class for LIMS2::Model::Schema::Result::Crispr

=cut

sub all_tests : Tests {
    my $user                 = 'lims2';
    my $connect_entry        = 'LIMS2_DB';
    my $rs_species           = 'Species';
    my $rs_crisprs_loci_type = 'CrisprLociType';
    my (%species_record)           = ( 'id' => 'Alien', );
    my (%crisprs_loci_type_record) = ( 'id' => 'Alionic', );
    my $rs                         = 'Crispr';
    my %record                     = (
        'id'                  => 9999,
        'seq'                 => 'CCAGGTTATGACCTTGATTTATT',
        'species_id'          => 'Alien',
        'crispr_loci_type_id' => 'Alionic',
        'comment'             => 'comment',
        'pam_right'           => 1,
        'wge_crispr_id'       => undef,
        'nonsense_crispr_original_crispr_id' => undef,
        'validated'           => 0,
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
    my $crisprs_loci_type_resultset = $schema->resultset($rs_crisprs_loci_type);
    ok( $crisprs_loci_type_resultset, 'LIMS2::Model::DBConnect obtained result set' );

    note("Cleanup before the tests");
    lives_ok { $resultset->search( \%record )->delete() } 'Deleting the existing test records';
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $crisprs_loci_type_resultset->search( \%crisprs_loci_type_record )->delete() }
    'Deleting the existing test records';

    note("Generating reference data CrisprLociType record");
    lives_ok { $crisprs_loci_type_resultset->search( \%crisprs_loci_type_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $crisprs_loci_type_resultset->create( \%crisprs_loci_type_record ) }
    'Inserting new record';

    note("Generating reference data Species record");
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting any existing test records';
    lives_ok { $species_resultset->create( \%species_record ) } 'Inserting new record';

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
    lives_ok { $species_resultset->search( \%species_record )->delete() }
    'Deleting the existing test records';
    lives_ok { $crisprs_loci_type_resultset->search( \%crisprs_loci_type_record )->delete() }
    'Deleting the existing test records';
}

1;

__END__

