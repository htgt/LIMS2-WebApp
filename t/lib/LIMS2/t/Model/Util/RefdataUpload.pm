package LIMS2::t::Model::Util::RefdataUpload;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::RefdataUpload;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/RefdataUpload.pm - test class for LIMS2::Model::Util::RefdataUpload

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

sub a00_reference_data : Tests {

    my $user          = 'lims2';
    my $connect_entry = 'LIMS2_DB';
    my $schema;
    my @fixtures = (
        { file => 'reference_data/Backbone.csv',                    schema => 'Backbone' },
        { file => 'reference_data/Cassette.csv',                    schema => 'Cassette' },
        { file => 'reference_data/CassetteFunction.csv',            schema => 'CassetteFunction' },
        { file => 'reference_data/CellLine.csv',                    schema => 'CellLine' },
        { file => 'reference_data/ColonyCountType.csv',             schema => 'ColonyCountType' },
        { file => 'reference_data/CrisprLociType.csv',              schema => 'CrisprLociType' },
        { file => 'reference_data/DesignCommentCategory.csv',       schema => 'DesignCommentCategory' },
        { file => 'reference_data/DesignOligoType.csv',             schema => 'DesignOligoType' },
        { file => 'reference_data/DesignType.csv',                  schema => 'DesignType' },
        { file => 'reference_data/GeneType.csv',                    schema => 'GeneType' },
        { file => 'reference_data/GenotypingPrimerType.csv',        schema => 'GenotypingPrimerType' },
        { file => 'reference_data/GenotypingResultType.csv',        schema => 'GenotypingResultType' },
        { file => 'reference_data/MutationDesignType.csv',          schema => 'MutationDesignType' },
        { file => 'reference_data/PlateType.csv',                   schema => 'PlateType' },
        { file => 'reference_data/PrimerBandType.csv',              schema => 'PrimerBandType' },
        { file => 'reference_data/ProcessType.csv',                 schema => 'ProcessType' },
        { file => 'reference_data/Recombinase.csv',                 schema => 'Recombinase' },
        { file => 'reference_data/RecombineeringResultType.csv',    schema => 'RecombineeringResultType' },
        { file => 'reference_data/Role.csv',                        schema => 'Role' },
        { file => 'reference_data/Species.csv',                     schema => 'Species' },
        { file => 'reference_data/Chromosome.csv',                  schema => 'Chromosome' },
        { file => 'reference_data/Assembly.csv',                    schema => 'Assembly' },
        { file => 'reference_data/BacLibrary.csv',                  schema => 'BacLibrary' },
        { file => 'reference_data/SpeciesDefaultAssembly.csv',      schema => 'SpeciesDefaultAssembly' },
        { file => 'reference_data/Sponsor.csv',                     schema => 'Sponsor' },
    );

    note('Connecting to database');

    ok( $ENV{$connect_entry} ne '', '$ENV{LIMS2_DB} has been set up' );
    $schema = LIMS2::Model::DBConnect->connect( $connect_entry, $user );
    ok( $schema, 'LIMS2::Model::DBConnect connected to the database' );

    note('Loading simple files');

    my $fixture;
    for my $test (@fixtures) {
        lives_ok { $fixture = fixture_data( $test->{file} ) } 'Expecting to live';
        my $rs = $schema->resultset( $test->{schema} );
        ok( $rs, 'LIMS2::Model::DBConnect obtained result set' );
        lives_ok { LIMS2::Model::Util::RefdataUpload::load_csv_file( $fixture, $rs ) }
        'Loading up csv file';
    }
}

## use critic

1;

__END__

