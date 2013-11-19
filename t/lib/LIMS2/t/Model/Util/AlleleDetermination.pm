package LIMS2::t::Model::Util::AlleleDetermination;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::AlleleDetermination;
use LIMS2::Test;
use strict;

use Data::Dumper;

## no critic

=head1 NAME

LIMS2/t/Model/Util/AlleleDetermination.pm - test class for LIMS2::Model::Util::AlleleDetermination

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

sub all_tests : Test(217) {
    ok( 1, "Test of LIMS2::Model::Util::AlleleDetermination" );

    note('Testing AlleleDetermination Logic - step 1 - loading test data from yaml file');

    ok my $test_data = test_data('10_LIMS2_Model_Util_AlleleDetermination.yaml'),
        'fetching test data yaml file should succeed';

    # fetch workflow Ne1a data
    note('Testing AlleleDetermination Logic - step 2a - extracting Ne1a workflow data');
    ok my $ne1a_gqc_yaml_data = $test_data->{'workflow_ne1a_gc_results'},
        'fetching Ne1a test data from yaml should succeed';

    # Create a new connection Model to link to DB
    ok my $model = LIMS2::Model->new( user => 'tests' ), 'creating a new DB model connection should succeed';

    # Create AlleleDetermination module instance
    ok my $ne1a_AD = LIMS2::Model::Util::AlleleDetermination->new( model => $model, species => 'Mouse' ),
        'creating instance of module should succeed';

# Set the genotyping results hash in the module instance
# ok $ne1a_AD->well_genotyping_results ( $ne1a_well_gc_results ), 'setting well gc results hash in module instance should succeed';
    ok $ne1a_AD->well_genotyping_results_array($ne1a_gqc_yaml_data),
        'setting well gc results array in module instance should succeed';

    note('Testing AlleleDetermination Logic - step 2b - determining Ne1a workflow allele types');

    # calculate the allele types
    ok my $ne1a_gc_allele_results_array = $ne1a_AD->test_determine_allele_types_logic(),
        'calculating Ne1a allele types should succeed';

    #   id   Ne1a workflow:         stage       pattern (crit, tam, del, neo, bsd):
    #   1    'wt/wt'                EP_PICK     22200
    #   2    'tm1a/wt'              EP_PICK     21110
    #   3    'tm1e/wt'              EP_PICK     22110

    #   4    'wt/wt'                SEP_PICK    22200
    #   5    'tm1a/wt'              SEP_PICK    21110
    #   6    'tm1e/wt'              SEP_PICK    22110
    #   7    'wt/tm1'               SEP_PICK    11101
    #   8    'tm1e/tm1'             SEP_PICK    11011
    #   9    'tm1a/tm1'             SEP_PICK    10011
    #   10   'tm1a/wt+bsd_offtarg'  SEP_PICK    21111
    #   11   'wt+neo_offtarg/tm1'   SEP_PICK    11111

    #   12   'potential wt/wt'      EP_PICK     22200
    #   13   'potential tm1a/wt'    EP_PICK     21110
    #   14   'potential tm1e/wt'    EP_PICK     22110

    #   15   'potential wt/wt'      SEP_PICK    22200
    #   16   'potential tm1a/wt'    SEP_PICK    21110
    #   17   'potential tm1e/wt'    SEP_PICK    22110
    #   18   'potential wt/tm1'     SEP_PICK    11101
    #   19   'potential tm1e/tm1'   SEP_PICK    11011
    #   20   'potential tm1a/tm1'   SEP_PICK    10011
    #   21   'unknown'
    #   22   'failed: loacrit assay validation: Copy Number not present'
    #   23   'failed: loacrit assay validation: Copy Number Range not present'
    #   24   'failed: loacrit assay validation: Copy Number Range above threshold'
    #   25   'failed: loatam assay validation: Copy Number not present'
    #   26   'failed: loatam assay validation: Copy Number Range not present'
    #   27   'failed: loatam assay validation: Copy Number Range above threshold'
    #   28   'failed: loadel assay validation: Copy Number not present'
    #   29   'failed: loadel assay validation: Copy Number Range not present'
    #   30   'failed: loadel assay validation: Copy Number Range above threshold'
    #   31   'failed: neo assay validation: Copy Number not present'
    #   32   'failed: neo assay validation: Copy Number Range not present'
    #   33   'failed: neo assay validation: Copy Number Range above threshold'
    #   34   'failed: bsd assay validation: Copy Number not present'
    #   35   'failed: bsd assay validation: Copy Number Range not present'
    #   36   'failed: bsd assay validation: Copy Number Range above threshold'

    # check each allele type returned matches the expected types
    note('Testing AlleleDetermination Logic - step 2c - checking Ne1a workflow allele types');

    my $ne1a_gc_allele_results = {};
    foreach my $ne1a_well_result_hash ( @{ $ne1a_gc_allele_results_array } ) {
        $ne1a_gc_allele_results->{ $ne1a_well_result_hash->{ 'id' } } = $ne1a_well_result_hash;
    }

    print "ne1a_gc_allele_results:\n";
    print Dumper ( $ne1a_gc_allele_results );

    ok $ne1a_gc_allele_results->{ '1' }->{ 'allele_determination' } eq 'wt/wt',   'well 1 should be allele type < wt/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_results->{ '1' }->{ 'genotyping_pass' } eq 'fail', 'well 1 should be an EP_PICK genotyping pass failure as not wanted genotype';
    ok $ne1a_gc_allele_results->{ '2' }->{ 'allele_determination' } eq 'tm1a/wt', 'well 2 should be allele type < tm1a/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_results->{ '2' }->{ 'genotyping_pass' } eq 'pass', 'well 2 should be an EP_PICK genotyping pass';
    print $ne1a_gc_allele_results->{ '2' }->{ 'genotyping_pass' } . "\n";
    ok $ne1a_gc_allele_results->{ '3' }->{ 'allele_determination' } eq 'tm1e/wt', 'well 3 should be allele type < tm1e/wt > for stage EP_PICK';

    ok $ne1a_gc_allele_results->{ '4' }->{ 'allele_determination' } eq 'wt/wt',    'well 4 should be allele type < wt/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '4' }->{ 'genotyping_pass' } eq 'fail', 'well 4 should be an SEP_PICK genotyping pass failure as not wanted genotype';
    ok $ne1a_gc_allele_results->{ '5' }->{ 'allele_determination' } eq 'tm1a/wt',  'well 5 should be allele type < tm1a/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '6' }->{ 'allele_determination' } eq 'tm1e/wt',  'well 6 should be allele type < tm1e/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '7' }->{ 'allele_determination' } eq 'wt/tm1',   'well 7 should be allele type < wt/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '8' }->{ 'allele_determination' } eq 'tm1e/tm1', 'well 8 should be allele type < tm1e/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '9' }->{ 'allele_determination' } eq 'tm1a/tm1', 'well 9 should be allele type < tm1a/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '9' }->{ 'genotyping_pass' } eq 'pass', 'well 9 should be an SEP_PICK genotyping pass';
    print $ne1a_gc_allele_results->{ '9' }->{ 'genotyping_pass' } . "\n";
    ok $ne1a_gc_allele_results->{ '10' }->{ 'allele_determination' } eq 'tm1a/wt+bsd_offtarg',
        'well 10 should be allele type < tm1a/wt+bsd_offtarg > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '11' }->{ 'allele_determination' } eq 'wt+neo_offtarg/tm1',
        'well 11 should be allele type < wt+neo_offtarg/tm1 > for stage SEP_PICK';

    ok $ne1a_gc_allele_results->{ '12' }->{ 'allele_determination' } eq 'potential wt/wt',
        'well 12 should be allele type < potential wt/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_results->{ '13' }->{ 'allele_determination' } eq 'potential tm1a/wt',
        'well 13 should be allele type < potential tm1a/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_results->{ '14' }->{ 'allele_determination' } eq 'potential tm1e/wt',
        'well 14 should be allele type < potential tm1e/wt > for stage EP_PICK';

    ok $ne1a_gc_allele_results->{ '15' }->{ 'allele_determination' } eq 'potential wt/wt',
        'well 15 should be allele type < potential wt/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '16' }->{ 'allele_determination' } eq 'potential tm1a/wt',
        'well 16 should be allele type < potential tm1a/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '17' }->{ 'allele_determination' } eq 'potential tm1e/wt',
        'well 17 should be allele type < potential tm1e/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '18' }->{ 'allele_determination' } eq 'potential wt/tm1',
        'well 18 should be allele type < potential wt/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '19' }->{ 'allele_determination' } eq 'potential tm1e/tm1',
        'well 19 should be allele type < potential tm1e/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_results->{ '20' }->{ 'allele_determination' } eq 'potential tm1a/tm1',
        'well 20 should be allele type < potential tm1a/tm1 > for stage SEP_PICK';

    ok $ne1a_gc_allele_results->{ '21' }->{ 'allele_determination' } eq
        'Failed: unknown allele pattern : Ne1a SEP_PICK bsd:1.1 loacrit:1.1 loadel:1.1 loatam:0.1 neo:1.1',
        'well 21 should give an unknown allele pattern error';

    ok $ne1a_gc_allele_results->{ '22' }->{ 'allele_determination' } eq 'Failed: validate assays : loacrit assay validation: Copy Number not present. ',
        'well 22 should give a validation error for missing loacrit copy number';
    ok $ne1a_gc_allele_results->{ '23' }->{ 'allele_determination' } eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range not present. ',
        'well 23 should give a validation error for missing loacrit copy number range';
    ok $ne1a_gc_allele_results->{ '24' }->{ 'allele_determination' } eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range above threshold. ',
        'well 24 should give a validation error for above threshold loacrit copy number range';

    ok $ne1a_gc_allele_results->{ '25' }->{ 'allele_determination' } eq 'Failed: validate assays : loatam assay validation: Copy Number not present. ',
        'well 25 should give a validation error for missing loatam copy number';
    ok $ne1a_gc_allele_results->{ '26' }->{ 'allele_determination' } eq
        'Failed: validate assays : loatam assay validation: Copy Number Range not present. ',
        'well 26 should give a validation error for missing loatam copy number range';
    ok $ne1a_gc_allele_results->{ '27' }->{ 'allele_determination' } eq
        'Failed: validate assays : loatam assay validation: Copy Number Range above threshold. ',
        'well 27 should give a validation error for above threshold loatam copy number range';

    ok $ne1a_gc_allele_results->{ '28' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number not present. ',
        'well 28 should give a validation error for missing loadel copy number';
    ok $ne1a_gc_allele_results->{ '29' }->{ 'allele_determination' } eq
        'Failed: validate assays : loadel assay validation: Copy Number Range not present. ',
        'well 29 should give a validation error for missing loadel copy number range';
    ok $ne1a_gc_allele_results->{ '30' }->{ 'allele_determination' } eq
        'Failed: validate assays : loadel assay validation: Copy Number Range above threshold. ',
        'well 30 should give a validation error for above threshold loadel copy number range';

    ok $ne1a_gc_allele_results->{ '31' }->{ 'allele_determination' } eq 'Failed: validate assays : neo assay validation: Copy Number not present. ',
        'well 31 should give a validation error for missing neo copy number';
    ok $ne1a_gc_allele_results->{ '32' }->{ 'allele_determination' } eq 'Failed: validate assays : neo assay validation: Copy Number Range not present. ',
        'well 32 should give a validation error for missing neo copy number range';
    ok $ne1a_gc_allele_results->{ '33' }->{ 'allele_determination' } eq
        'Failed: validate assays : neo assay validation: Copy Number Range above threshold. ',
        'well 33 should give a validation error for above threshold neo copy number range';

    ok $ne1a_gc_allele_results->{ '34' }->{ 'allele_determination' } eq 'Failed: validate assays : bsd assay validation: Copy Number not present. ',
        'well 34 should give a validation error for missing bsd copy number';
    ok $ne1a_gc_allele_results->{ '35' }->{ 'allele_determination' } eq 'Failed: validate assays : bsd assay validation: Copy Number Range not present. ',
        'well 35 should give a validation error for missing bsd copy number range';
    ok $ne1a_gc_allele_results->{ '36' }->{ 'allele_determination' } eq
        'Failed: validate assays : bsd assay validation: Copy Number Range above threshold. ',
        'well 36 should give a validation error for above threshold bsd copy number range';

    # ----------------------------------------------------------------------------------------------
    # TODO: test genotyping Pass logic here
    # ----------------------------------------------------------------------------------------------

    # fetch workflow Ne1 data
    note('Testing AlleleDetermination Logic - step 3a - extracting Ne1 workflow data');
    ok my $ne1_gqc_yaml_data = $test_data->{'workflow_ne1_gc_results'},
        'fetching Ne1 test data from yaml should succeed';

    # Create AlleleDetermination module instance
    ok my $ne1_AD = LIMS2::Model::Util::AlleleDetermination->new( model => $model, species => 'Mouse' ),
        'creating instance of module should succeed';

    # Set the genotyping results hash in the module instance
    # ok $ne1_AD->well_genotyping_results ( $ne1_well_gc_results ), 'setting well gc results hash in module instance should succeed';
    ok $ne1_AD->well_genotyping_results_array($ne1_gqc_yaml_data),
        'setting well gc results array in module instance should succeed';

    note('Testing AlleleDetermination Logic - step 3b - determining Ne1 workflow allele types');

    # calculate the allele types
    ok my $ne1_gc_allele_results_array = $ne1_AD->test_determine_allele_types_logic(),
        'calculating Ne1 allele types should succeed';

    #   id   Ne1 workflow:          stage       pattern (crit, tam, del, neo, bsd, en2-int):
    #   1   'wt/wt'                 EP_PICK     222000
    #   2   'tm1/wt'                EP_PICK     111011

    #   3   'wt/wt'                 SEP_PICK    222000
    #   4   'tm1/wt'                SEP_PICK    111011
    #   5   'tm1/tm1a'              SEP_PICK    100112
    #   6   'wt/tm1a'               SEP_PICK    211101
    #   7   'tm1/tm1e'              SEP_PICK    110112
    #   8   'wt/tm1e'               SEP_PICK    111101
    #TODO: any off target types here?
    #   9   'potential wt/wt'       EP_PICK     222000
    #   10  'potential tm1/wt'      EP_PICK     111011

    #   11  'potential wt/wt'       SEP_PICK    222000
    #   12  'potential tm1/wt'      SEP_PICK    111011
    #   13  'potential tm1/tm1a'    SEP_PICK    100112
    #   14  'potential wt/tm1a'     SEP_PICK    211101
    #   15  'potential tm1/tm1e'    SEP_PICK    110112
    #   16  'potential wt/tm1e'     SEP_PICK    111101
    #   17  'unknown'
    #   18  'failed: loacrit assay validation: Copy Number not present'
    #   19  'failed: loacrit assay validation: Copy Number Range not present'
    #   20  'failed: loacrit assay validation: Copy Number Range above threshold'
    #   21  'failed: loatam assay validation: Copy Number not present'
    #   22  'failed: loatam assay validation: Copy Number Range not present'
    #   23  'failed: loatam assay validation: Copy Number Range above threshold'
    #   24  'failed: loadel assay validation: Copy Number not present'
    #   25  'failed: loadel assay validation: Copy Number Range not present'
    #   26  'failed: loadel assay validation: Copy Number Range above threshold'
    #   27  'failed: neo assay validation: Copy Number not present'
    #   28  'failed: neo assay validation: Copy Number Range not present'
    #   29  'failed: neo assay validation: Copy Number Range above threshold'
    #   30  'failed: bsd assay validation: Copy Number not present'
    #   31  'failed: bsd assay validation: Copy Number Range not present'
    #   32  'failed: bsd assay validation: Copy Number Range above threshold'
    #   33  'failed: en2-int assay validation: Copy Number not present'
    #   34  'failed: en2-int assay validation: Copy Number Range not present'
    #   35  'failed: en2-int assay validation: Copy Number Range above threshold'

    # check each allele type returned matches the expected types
    note('Testing AlleleDetermination Logic - step 3c - checking Ne1 workflow allele types');

    my $ne1_gc_allele_results = {};
    foreach my $ne1_well_result_hash ( @{ $ne1_gc_allele_results_array } ) {
        $ne1_gc_allele_results->{ $ne1_well_result_hash->{ 'id' } } = $ne1_well_result_hash;
    }

    print "ne1_gc_allele_results:\n";
    print Dumper ( $ne1_gc_allele_results );

    ok $ne1_gc_allele_results->{ '1' }->{ 'allele_determination' } eq 'wt/wt',  'well 1 should be allele type < wt/wt > for stage EP_PICK';
    ok $ne1_gc_allele_results->{ '1' }->{ 'genotyping_pass' } eq 'fail', 'well 1 should be an EP_PICK genotyping pass failure as not wanted genotype';
    ok $ne1_gc_allele_results->{ '2' }->{ 'allele_determination' } eq 'tm1/wt', 'well 2 should be allele type < tm1/wt > for stage EP_PICK';
    ok $ne1_gc_allele_results->{ '2' }->{ 'genotyping_pass' } eq 'pass', 'well 2 should be an EP_PICK genotyping pass';
    
    ok $ne1_gc_allele_results->{ '3' }->{ 'allele_determination' } eq 'wt/wt',    'well 3 should be allele type < wt/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '3' }->{ 'genotyping_pass' } eq 'fail', 'well 3 should be an SEP_PICK genotyping pass failure as not wanted genotype';
    ok $ne1_gc_allele_results->{ '4' }->{ 'allele_determination' } eq 'tm1/wt',   'well 4 should be allele type < tm1/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '5' }->{ 'allele_determination' } eq 'tm1/tm1a', 'well 5 should be allele type < tm1/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '5' }->{ 'genotyping_pass' } eq 'pass', 'well 5 should be an SEP_PICK genotyping pass';
    ok $ne1_gc_allele_results->{ '6' }->{ 'allele_determination' } eq 'wt/tm1a',  'well 6 should be allele type < wt/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '7' }->{ 'allele_determination' } eq 'tm1/tm1e', 'well 7 should be allele type < tm1/tm1e > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '8' }->{ 'allele_determination' } eq 'wt/tm1e',  'well 8 should be allele type < wt/tm1e > for stage SEP_PICK';

    ok $ne1_gc_allele_results->{ '9' }->{ 'allele_determination' } eq 'potential wt/wt',
        'well 9 should be allele type < potential wt/wt > for stage EP_PICK';
    ok $ne1_gc_allele_results->{ '10' }->{ 'allele_determination' } eq 'potential tm1/wt',
        'well 10 should be allele type < potential tm1/wt > for stage EP_PICK';

    ok $ne1_gc_allele_results->{ '11' }->{ 'allele_determination' } eq 'potential wt/wt',
        'well 11 should be allele type < potential wt/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '12' }->{ 'allele_determination' } eq 'potential tm1/wt',
        'well 12 should be allele type < potential tm1/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '13' }->{ 'allele_determination' } eq 'potential tm1/tm1a',
        'well 13 should be allele type < potential tm1/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '14' }->{ 'allele_determination' } eq 'potential wt/tm1a',
        'well 14 should be allele type < potential wt/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '15' }->{ 'allele_determination' } eq 'potential tm1/tm1e',
        'well 15 should be allele type < potential tm1/tm1e > for stage SEP_PICK';
    ok $ne1_gc_allele_results->{ '16' }->{ 'allele_determination' } eq 'potential wt/tm1e',
        'well 16 should be allele type < potential wt/tm1e > for stage SEP_PICK';

    ok $ne1_gc_allele_results->{ '17' }->{ 'allele_determination' } eq
        'Failed: unknown allele pattern : Ne1 SEP_PICK bsd:1.1 loacrit:1.1 loadel:1.1 loatam:0.1 neo:1.1',
        'well 17 should give an unknown allele pattern error';

    ok $ne1_gc_allele_results->{ '18' }->{ 'allele_determination' } eq 'Failed: validate assays : loacrit assay validation: Copy Number not present. ',
        'well 18 should give a validation error for missing loacrit copy number';
    ok $ne1_gc_allele_results->{ '19' }->{ 'allele_determination' } eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range not present. ',
        'well 19 should give a validation error for missing loacrit copy number range';
    ok $ne1_gc_allele_results->{ '20' }->{ 'allele_determination' } eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range above threshold. ',
        'well 20 should give a validation error for above threshold loacrit copy number range';

    ok $ne1_gc_allele_results->{ '21' }->{ 'allele_determination' } eq 'Failed: validate assays : loatam assay validation: Copy Number not present. ',
        'well 21 should give a validation error for missing loatam copy number';
    ok $ne1_gc_allele_results->{ '22' }->{ 'allele_determination' } eq
        'Failed: validate assays : loatam assay validation: Copy Number Range not present. ',
        'well 22 should give a validation error for missing loatam copy number range';
    ok $ne1_gc_allele_results->{ '23' }->{ 'allele_determination' } eq
        'Failed: validate assays : loatam assay validation: Copy Number Range above threshold. ',
        'well 23 should give a validation error for above threshold loatam copy number range';

    ok $ne1_gc_allele_results->{ '24' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number not present. ',
        'well 24 should give a validation error for missing loadel copy number';
    ok $ne1_gc_allele_results->{ '25' }->{ 'allele_determination' } eq
        'Failed: validate assays : loadel assay validation: Copy Number Range not present. ',
        'well 25 should give a validation error for missing loadel copy number range';
    ok $ne1_gc_allele_results->{ '26' }->{ 'allele_determination' } eq
        'Failed: validate assays : loadel assay validation: Copy Number Range above threshold. ',
        'well 26 should give a validation error for above threshold loadel copy number range';

    ok $ne1_gc_allele_results->{ '27' }->{ 'allele_determination' } eq 'Failed: validate assays : neo assay validation: Copy Number not present. ',
        'well 27 should give a validation error for missing neo copy number';
    ok $ne1_gc_allele_results->{ '28' }->{ 'allele_determination' } eq 'Failed: validate assays : neo assay validation: Copy Number Range not present. ',
        'well 28 should give a validation error for missing neo copy number range';
    ok $ne1_gc_allele_results->{ '29' }->{ 'allele_determination' } eq
        'Failed: validate assays : neo assay validation: Copy Number Range above threshold. ',
        'well 29 should give a validation error for above threshold neo copy number range';

    ok $ne1_gc_allele_results->{ '30' }->{ 'allele_determination' } eq 'Failed: validate assays : bsd assay validation: Copy Number not present. ',
        'well 30 should give a validation error for missing bsd copy number';
    ok $ne1_gc_allele_results->{ '31' }->{ 'allele_determination' } eq 'Failed: validate assays : bsd assay validation: Copy Number Range not present. ',
        'well 31 should give a validation error for missing bsd copy number range';
    ok $ne1_gc_allele_results->{ '32' }->{ 'allele_determination' } eq
        'Failed: validate assays : bsd assay validation: Copy Number Range above threshold. ',
        'well 32 should give a validation error for above threshold bsd copy number range';

    # ----------------------------------------------------------------------------------------------
    # TODO: test genotyping Pass logic here
    # ----------------------------------------------------------------------------------------------

    # fetch workflow E data
    note('Testing AlleleDetermination Logic - 4a - extracting Essential workflow data');
    ok my $e_gqc_yaml_data = $test_data->{'workflow_e_gc_results'}, 'fetching E test data from yaml should succeed';

    # Create AlleleDetermination module instance
    ok my $e_AD = LIMS2::Model::Util::AlleleDetermination->new( model => $model, species => 'Mouse' ),
        'creating instance of module should succeed';

    # Set the genotyping results hash in the module instance
    # ok $e_AD->well_genotyping_results ( $e_well_gc_results ), 'setting well gc results hash in module instance should succeed';
    ok $e_AD->well_genotyping_results_array($e_gqc_yaml_data),
        'setting well gc results array in module instance should succeed';

    note('Testing AlleleDetermination Logic - step 4b - determining Essential workflow allele types');

    # calculate the allele types
    ok my $e_gc_allele_results_array = $e_AD->test_determine_allele_types_logic(), 'calculating E allele types should succeed';

    #   id   E workflow:            stage       pattern (crit, tam, del, neo, bsd):
    #   1   'wt/wt'                 EP_PICK     22200       shows as wt/wt, tm1f/wt when only crit, tam and neo tests done
    #   2   'tm1a/wt'               EP_PICK     21110
    #   3   'tm1c/wt'               EP_PICK     21100
    #   4   'tm1e/wt'               EP_PICK     22110
    #   5   'tm1f/wt'               EP_PICK     22100       shows as wt/wt, tm1f/wt when only crit, tam and neo tests done

    #   6   'wt/wt'                 SEP_PICK    22200
    #   7   'tm1a/wt'               SEP_PICK    21110
    #   8   'tm1c/wt'               SEP_PICK    21100
    #   9   'tm1e/wt'               SEP_PICK    22110
    #   10  'tm1f/wt'               SEP_PICK    22100
    #   11  'wt/tm1'                SEP_PICK    11101
    #   12  'tm1a/tm1'              SEP_PICK    10011
    #   13  'tm1c/tm1'              SEP_PICK    10001
    #   14  'tm1e/tm1'              SEP_PICK    11011
    #   15  'tm1f/tm1'              SEP_PICK    11001
    #TODO: any off target types here?
    #   16  'potential wt/wt'       EP_PICK     22200       shows as potential wt/wt, potential tm1f/wt when only crit, tam and neo tests done
    #   17  'potential tm1a/wt'     EP_PICK     21110
    #   18  'potential tm1c/wt'     EP_PICK     21100
    #   19  'potential tm1e/wt'     EP_PICK     22110
    #   20  'potential tm1f/wt'     EP_PICK     22100       shows as potential wt/wt, potential tm1f/wt when only crit, tam and neo tests done

    #   21  'potential wt/wt'       SEP_PICK    22200
    #   22  'potential tm1a/wt'     SEP_PICK    21110
    #   23  'potential tm1c/wt'     SEP_PICK    21100
    #   24  'potential tm1e/wt'     SEP_PICK    22110
    #   25  'potential tm1f/wt'     SEP_PICK    22100
    #   26  'potential wt/tm1'      SEP_PICK    11101
    #   27  'potential tm1a/tm1'    SEP_PICK    10011
    #   28  'potential tm1c/tm1'    SEP_PICK    10001
    #   29  'potential tm1e/tm1'    SEP_PICK    11011
    #   30  'potential tm1f/tm1'    SEP_PICK    11001

    #   31  'unknown'
    #   32  'failed: loacrit assay validation: Copy Number not present'
    #   33  'failed: loacrit assay validation: Copy Number Range not present'
    #   34  'failed: loacrit assay validation: Copy Number Range above threshold'
    #   35  'failed: loatam assay validation: Copy Number not present'
    #   36  'failed: loatam assay validation: Copy Number Range not present'
    #   37  'failed: loatam assay validation: Copy Number Range above threshold'
    #   38  'failed: loadel assay validation: Copy Number not present'
    #   39  'failed: loadel assay validation: Copy Number Range not present'
    #   40  'failed: loadel assay validation: Copy Number Range above threshold'
    #   41  'failed: neo assay validation: Copy Number not present'
    #   42  'failed: neo assay validation: Copy Number Range not present'
    #   43  'failed: neo assay validation: Copy Number Range above threshold'
    #   44  'failed: bsd assay validation: Copy Number not present'
    #   45  'failed: bsd assay validation: Copy Number Range not present'
    #   46  'failed: bsd assay validation: Copy Number Range above threshold'

    # check each allele type returned matches the expected types
    note('Testing AlleleDetermination Logic - step 4c - checking Essential workflow allele types');

    my $e_gc_allele_results = {};
    foreach my $e_well_result_hash ( @{ $e_gc_allele_results_array } ) {
        $e_gc_allele_results->{ $e_well_result_hash->{ 'id' } } = $e_well_result_hash;
    }


    print "e_gc_allele_results:\n";
    print Dumper ( $e_gc_allele_results );

    ok $e_gc_allele_results->{ '1' }->{ 'allele_determination' } eq 'tm1f/wt; wt/wt', 'well 1 should be allele type < tm1f/wt, wt/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '1' }->{ 'genotyping_pass' } eq 'fail', 'well 1 should be an EP_PICK genotyping pass failure as not wanted genotype';
    ok $e_gc_allele_results->{ '2' }->{ 'allele_determination' } eq 'tm1a/wt', 'well 2 should be allele type < tm1a/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '3' }->{ 'allele_determination' } eq 'tm1c/wt', 'well 3 should be allele type < tm1c/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '3' }->{ 'genotyping_pass' } eq 'pass', 'well 3 should be an EP_PICK genotyping pass';
    ok $e_gc_allele_results->{ '4' }->{ 'allele_determination' } eq 'tm1e/wt', 'well 4 should be allele type < tm1e/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '5' }->{ 'allele_determination' } eq 'tm1f/wt; wt/wt', 'well 5 should be allele type < tm1f/wt, wt/wt > for stage EP_PICK';

    ok $e_gc_allele_results->{ '6'}->{ 'allele_determination' } eq 'wt/wt',    'well 6 should be allele type < wt/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '6' }->{ 'genotyping_pass' } eq 'fail', 'well 6 should be an SEP_PICK genotyping pass failure as not wanted genotype';
    ok $e_gc_allele_results->{ '7'}->{ 'allele_determination' } eq 'tm1a/wt',  'well 7 should be allele type < tm1a/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '8'}->{ 'allele_determination' } eq 'tm1c/wt',  'well 8 should be allele type < tm1c/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '9'}->{ 'allele_determination' } eq 'tm1e/wt',  'well 9 should be allele type < tm1e/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '10' }->{ 'allele_determination' } eq 'tm1f/wt',  'well 10 should be allele type < tm1f/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '11' }->{ 'allele_determination' } eq 'wt/tm1',   'well 11 should be allele type < wt/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '12' }->{ 'allele_determination' } eq 'tm1a/tm1', 'well 12 should be allele type < tm1a/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '13' }->{ 'allele_determination' } eq 'tm1c/tm1', 'well 13 should be allele type < tm1c/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '13' }->{ 'genotyping_pass' } eq 'pass', 'well 13 should be an SEP_PICK genotyping pass';
    ok $e_gc_allele_results->{ '14' }->{ 'allele_determination' } eq 'tm1e/tm1', 'well 14 should be allele type < tm1e/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '15' }->{ 'allele_determination' } eq 'tm1f/tm1', 'well 15 should be allele type < tm1f/tm1 > for stage SEP_PICK';

    ok $e_gc_allele_results->{ '16' }->{ 'allele_determination' } eq 'potential tm1f/wt; potential wt/wt',
        'well 16 should be allele type < potential tm1f/wt, potential wt/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '17' }->{ 'allele_determination' } eq 'potential tm1a/wt',
        'well 17 should be allele type < potential tm1a/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '18' }->{ 'allele_determination' } eq 'potential tm1c/wt',
        'well 18 should be allele type < potential tm1c/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '19' }->{ 'allele_determination' } eq 'potential tm1e/wt',
        'well 19 should be allele type < potential tm1e/wt > for stage EP_PICK';
    ok $e_gc_allele_results->{ '20' }->{ 'allele_determination' } eq 'potential tm1f/wt; potential wt/wt',
        'well 20 should be allele type < potential tm1f/wt, potential wt/wt > for stage EP_PICK';

    ok $e_gc_allele_results->{ '21' }->{ 'allele_determination' } eq 'potential wt/wt',
        'well 21 should be allele type < potential wt/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '22' }->{ 'allele_determination' } eq 'potential tm1a/wt',
        'well 22 should be allele type < potential tm1a/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '23' }->{ 'allele_determination' } eq 'potential tm1c/wt',
        'well 23 should be allele type < potential tm1c/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '24' }->{ 'allele_determination' } eq 'potential tm1e/wt',
        'well 24 should be allele type < potential tm1e/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '25' }->{ 'allele_determination' } eq 'potential tm1f/wt',
        'well 25 should be allele type < potential tm1f/wt > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '26' }->{ 'allele_determination' } eq 'potential wt/tm1',
        'well 26 should be allele type < potential wt/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '27' }->{ 'allele_determination' } eq 'potential tm1a/tm1',
        'well 27 should be allele type < potential tm1a/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '28' }->{ 'allele_determination' } eq 'potential tm1c/tm1',
        'well 28 should be allele type < potential tm1c/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '29' }->{ 'allele_determination' } eq 'potential tm1e/tm1',
        'well 29 should be allele type < potential tm1e/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_results->{ '30' }->{ 'allele_determination' } eq 'potential tm1f/tm1',
        'well 30 should be allele type < potential tm1f/tm1 > for stage SEP_PICK';

    ok $e_gc_allele_results->{ '31' }->{ 'allele_determination' } eq
        'Failed: unknown allele pattern : E SEP_PICK bsd:1.1 loacrit:1.1 loadel:1.1 loatam:0.1 neo:1.1',
        'well 31 should give an unknown allele pattern error';

    ok $e_gc_allele_results->{ '32' }->{ 'allele_determination' } eq 'Failed: validate assays : loacrit assay validation: Copy Number not present. ',
        'well 32 should give a validation error for missing loacrit copy number';
    ok $e_gc_allele_results->{ '33' }->{ 'allele_determination' } eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range not present. ',
        'well 33 should give a validation error for missing loacrit copy number range';
    ok $e_gc_allele_results->{ '34' }->{ 'allele_determination' } eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range above threshold. ',
        'well 34 should give a validation error for above threshold loacrit copy number range';

    ok $e_gc_allele_results->{ '35' }->{ 'allele_determination' } eq 'Failed: validate assays : loatam assay validation: Copy Number not present. ',
        'well 35 should give a validation error for missing loatam copy number';
    ok $e_gc_allele_results->{ '36' }->{ 'allele_determination' } eq 'Failed: validate assays : loatam assay validation: Copy Number Range not present. ',
        'well 36 should give a validation error for missing loatam copy number range';
    ok $e_gc_allele_results->{ '37' }->{ 'allele_determination' } eq
        'Failed: validate assays : loatam assay validation: Copy Number Range above threshold. ',
        'well 37 should give a validation error for above threshold loatam copy number range';

    ok $e_gc_allele_results->{ '38' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number not present. ',
        'well 38 should give a validation error for missing loadel copy number';
    ok $e_gc_allele_results->{ '39' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number Range not present. ',
        'well 39 should give a validation error for missing loadel copy number range';
    ok $e_gc_allele_results->{ '40' }->{ 'allele_determination' } eq
        'Failed: validate assays : loadel assay validation: Copy Number Range above threshold. ',
        'well 40 should give a validation error for above threshold loadel copy number range';

    ok $e_gc_allele_results->{ '41' }->{ 'allele_determination' } eq 'Failed: validate assays : neo assay validation: Copy Number not present. ',
        'well 41 should give a validation error for missing neo copy number';
    ok $e_gc_allele_results->{ '42' }->{ 'allele_determination' } eq 'Failed: validate assays : neo assay validation: Copy Number Range not present. ',
        'well 42 should give a validation error for missing neo copy number range';
    ok $e_gc_allele_results->{ '43' }->{ 'allele_determination' } eq
        'Failed: validate assays : neo assay validation: Copy Number Range above threshold. ',
        'well 43 should give a validation error for above threshold neo copy number range';

    ok $e_gc_allele_results->{ '44' }->{ 'allele_determination' } eq 'Failed: validate assays : bsd assay validation: Copy Number not present. ',
        'well 44 should give a validation error for missing bsd copy number';
    ok $e_gc_allele_results->{ '45' }->{ 'allele_determination' } eq 'Failed: validate assays : bsd assay validation: Copy Number Range not present. ',
        'well 45 should give a validation error for missing bsd copy number range';
    ok $e_gc_allele_results->{ '46' }->{ 'allele_determination' } eq
        'Failed: validate assays : bsd assay validation: Copy Number Range above threshold. ',
        'well 46 should give a validation error for above threshold bsd copy number range';

    # ----------------------------------------------------------------------------------------------
    # TODO: test genotyping Pass logic here
    # ----------------------------------------------------------------------------------------------

    # fetch CreKiDre workflow data
    note('Testing AlleleDetermination Logic - step 5a - extracting CreKi workflow data');
    ok my $creki_gqc_yaml_data = $test_data->{ 'workflow_creki_gc_results' }, 'fetching CreKi test data from yaml should succeed';

    # Create AlleleDetermination module instance
    ok my $creki_AD = LIMS2::Model::Util::AlleleDetermination->new( model => $model, species => 'Mouse' ),
        'creating instance of module should succeed';

    # Set the genotyping results hash in the module instance
    ok $creki_AD->well_genotyping_results_array($creki_gqc_yaml_data),
        'setting well gc results array in module instance should succeed';

    note('Testing AlleleDetermination Logic - 5b - determining CreKi workflow allele types');

    # calculate the allele types
    ok my $creki_gc_allele_results_array = $creki_AD->test_determine_allele_types_logic(), 'calculating CreKi allele types should succeed';

    #   id   CreKi workflow:         stage       pattern (cre, puro, loa del, lrpcr pass):
    #   1   'wt/wt'                  EP_PICK     002*
    #   2   'tm1/wt'                 EP_PICK     111*
    #   3   'tm1/wt lrpcr'           EP_PICK     11*1

    #   4   'wt/wt'                  PIQ         002*
    #   5   'tm1/wt'                 PIQ         111*
    #   6   'tm1/wt lrpcr'           PIQ         11*1
    
    #   7   'potential wt/wt'        EP_PICK     002*
    #   8   'potential tm1/wt'       EP_PICK     111*
    #   9   'potential tm1/wt lrpcr' EP_PICK     11*1

    #   10  'potential wt/wt'        PIQ         002*
    #   11  'potential tm1/wt'       PIQ         111*
    #   12  'potential tm1/wt lrpcr' PIQ         11*1

    #   13 'unknown'
    #   14  'failed: Cre assay validation: Copy Number not present'
    #   15  'failed: Cre assay validation: Copy Number Range not present'
    #   16  'failed: Cre assay validation: Copy Number Range above threshold'
    #   17  'failed: loadel assay validation: Copy Number not present'
    #   18  'failed: loadel assay validation: Copy Number Range not present'
    #   19  'failed: loadel assay validation: Copy Number Range above threshold'
    #   20  'failed: Puro assay validation: Copy Number not present'
    #   21  'failed: Puro assay validation: Copy Number Range not present'
    #   22  'failed: Puro assay validation: Copy Number Range above threshold'
    #   23  'failed: LRPCR assay validation: gr3 primer not present'
    #   24  test for 'passb_chr8a' genotyping pass result

    # check each allele type returned matches the expected types
    note('Testing AlleleDetermination Logic - 5c - checking CreKI workflow allele types');

    my $creki_gc_allele_results = {};
    foreach my $creki_well_result_hash ( @{ $creki_gc_allele_results_array } ) {
        $creki_gc_allele_results->{ $creki_well_result_hash->{ 'id' } } = $creki_well_result_hash;
    }

    print "creki_gc_allele_results:\n";
    print Dumper ( $creki_gc_allele_results );

    ok $creki_gc_allele_results->{ '1' }->{ 'allele_determination' }  eq 'wt/wt', 'well 1 should be allele type < wt/wt > for stage EP_PICK';
    ok $creki_gc_allele_results->{ '1' }->{ 'genotyping_pass' } eq 'fail', 'well 1 should be an EP_PICK genotyping pass failure as not wanted genotype';
    ok $creki_gc_allele_results->{ '2' }->{ 'allele_determination' }  eq 'tm1/wt', 'well 2 should be allele type < tm1/wt > for stage EP_PICK';
    ok $creki_gc_allele_results->{ '2' }->{ 'genotyping_pass' } eq 'pass', 'well 2 should be an EP_PICK genotyping pass';
    ok $creki_gc_allele_results->{ '3' }->{ 'allele_determination' }  eq 'tm1/wt lrpcr only', 'well 3 should be allele type < tm1/wt lrpcr only > for stage EP_PICK';
    ok $creki_gc_allele_results->{ '3' }->{ 'genotyping_pass' } eq 'pass', 'well 3 should be an EP_PICK (lrpcr) genotyping pass';

    ok $creki_gc_allele_results->{ '4' }->{ 'allele_determination' }  eq 'wt/wt', 'well 4 should be allele type < wt/wt > for stage PIQ';
    ok $creki_gc_allele_results->{ '4' }->{ 'genotyping_pass' } eq 'fail', 'well 4 should be a PIQ genotyping pass failure as not wanted genotype';
    ok $creki_gc_allele_results->{ '5' }->{ 'allele_determination' }  eq 'tm1/wt', 'well 5 should be allele type < tm1/wt > for stage PIQ';
    ok $creki_gc_allele_results->{ '5' }->{ 'genotyping_pass' } eq 'pass', 'well 5 should be a PIQ genotyping pass';
    ok $creki_gc_allele_results->{ '6' }->{ 'allele_determination' }  eq 'tm1/wt lrpcr only', 'well 6 should be allele type < tm1/wt lrpcr only > for stage PIQ';
    ok $creki_gc_allele_results->{ '6' }->{ 'genotyping_pass' } eq 'pass', 'well 6 should be a PIQ (lrpcr) genotyping pass';
    
    ok $creki_gc_allele_results->{ '7' }->{ 'allele_determination' }  eq 'potential wt/wt', 'well 7 should be allele type < potential wt/wt > for stage EP_PICK';
    ok $creki_gc_allele_results->{ '8' }->{ 'allele_determination' }  eq 'potential tm1/wt', 'well 8 should be allele type < potential tm1/wt > for stage EP_PICK';
    ok $creki_gc_allele_results->{ '9' }->{ 'allele_determination' }  eq 'potential tm1/wt lrpcr only', 'well 9 should be allele type < potential tm1/wt lrpcr only > for stage EP_PICK';

    ok $creki_gc_allele_results->{ '10' }->{ 'allele_determination' } eq 'potential wt/wt', 'well 10 should be allele type < potential wt/wt > for stage PIQ';
    ok $creki_gc_allele_results->{ '11' }->{ 'allele_determination' } eq 'potential tm1/wt', 'well 11 should be allele type < potential tm1/wt > for stage PIQ';
    ok $creki_gc_allele_results->{ '12' }->{ 'allele_determination' } eq 'potential tm1/wt lrpcr only', 'well 12 should be allele type < potential tm1/wt lrpcr only > for stage PIQ';

    ok $creki_gc_allele_results->{ '13' }->{ 'allele_determination' } eq 'Failed: unknown allele pattern : CreKi PIQ cre:2.1 puro:2.1 loadel:2.1 gr3:- gf3:- gr4:- gf4:-',
        'well 13 should give an unknown allele pattern error';

    ok $creki_gc_allele_results->{ '14' }->{ 'allele_determination' } eq 'Failed: validate assays : cre assay validation: Copy Number not present. ',
        'well 14 should give a validation error for missing Cre copy number';
    ok $creki_gc_allele_results->{ '15' }->{ 'allele_determination' } eq 'Failed: validate assays : cre assay validation: Copy Number Range not present. ',
        'well 15 should give a validation error for missing Cre copy number range';
    ok $creki_gc_allele_results->{ '16' }->{ 'allele_determination' } eq 'Failed: validate assays : cre assay validation: Copy Number Range above threshold. ',
        'well 16 should give a validation error for above threshold Cre copy number range';

    ok $creki_gc_allele_results->{ '17' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number not present. lrpcr assay validation: gf3 value not present. ',
        'well 17 should give a validation error for missing loadel copy number and no lrprc results';
    ok $creki_gc_allele_results->{ '18' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number Range not present. lrpcr assay validation: gf3 value not present. ',
        'well 18 should give a validation error for missing loadel copy number range and no lrprc results';
    ok $creki_gc_allele_results->{ '19' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number Range above threshold. lrpcr assay validation: gf3 value not present. ',
        'well 19 should give a validation error for above threshold loadel copy number range and no lrprc results';

    ok $creki_gc_allele_results->{ '20' }->{ 'allele_determination' } eq 'Failed: validate assays : puro assay validation: Copy Number not present. ',
        'well 20 should give a validation error for missing Puro copy number';
    ok $creki_gc_allele_results->{ '21' }->{ 'allele_determination' } eq 'Failed: validate assays : puro assay validation: Copy Number Range not present. ',
        'well 21 should give a validation error for missing Puro copy number range';
    ok $creki_gc_allele_results->{ '22' }->{ 'allele_determination' } eq 'Failed: validate assays : puro assay validation: Copy Number Range above threshold. ',
        'well 22 should give a validation error for above threshold Puro copy number range';
 
    ok $creki_gc_allele_results->{ '23' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number Range above threshold. lrpcr assay validation: gf3 value not present. ',
        'well 23 should give a error for a failed lrpcr test';

    ok $creki_gc_allele_results->{ '24' }->{ 'genotyping_pass' } eq 'passb_chr8a', 'well 24 should be a PIQ genotyping passb_chr8a';

    # ----------------------------------------------------------------------------------------------
    # TODO: test genotyping Pass logic here
    # ----------------------------------------------------------------------------------------------

    # fetch CreKiDre workflow data
    note('Testing AlleleDetermination Logic - step 6a - extracting CreKiDre workflow data');
    ok my $crekidre_gqc_yaml_data = $test_data->{'workflow_crekidre_gc_results'}, 'fetching CreKiDre test data from yaml should succeed';

    # Create AlleleDetermination module instance
    ok my $crekidre_AD = LIMS2::Model::Util::AlleleDetermination->new( model => $model, species => 'Mouse' ),
        'creating instance of module should succeed';

    # Set the genotyping results hash in the module instance
    ok $crekidre_AD->well_genotyping_results_array($crekidre_gqc_yaml_data),
        'setting well gc results array in module instance should succeed';

    note('Testing AlleleDetermination Logic - 6b - determining CreKiDre workflow allele types');

    # calculate the allele types
    ok my $crekidre_gc_allele_results_array = $crekidre_AD->test_determine_allele_types_logic(), 'calculating CreKiDre allele types should succeed';

    #   id   CreKiDre workflow:         stage       pattern (cre, puro, loa del, lrpcr pass):
    #   1   'wt/wt'                     EP_PICK     002*
    #   2   'tm1/wt'                    EP_PICK     111*
    #   3   'tm1/wt lrpcr'              EP_PICK     11*1
    #   4   'tm1.1/wt'                  EP_PICK     101*
    #   5   'tm1.1/wt lrpcr'            EP_PICK     10*1

    #   6   'wt/wt'                     PIQ         002*
    #   7   'tm1/wt'                    PIQ         111*
    #   8   'tm1/wt lrpcr'              PIQ         11*1
    #   9   'tm1.1/wt'                  PIQ         101*
    #   10  'tm1.1/wt lrpcr'            PIQ         10*1
    
    #   11  'potential wt/wt'           EP_PICK     002*
    #   12  'potential tm1/wt'          EP_PICK     111*
    #   13  'potential tm1/wt lrpcr'    EP_PICK     11*1
    #   14  'potential tm1.1/wt'        EP_PICK     101*
    #   15  'potential tm1.1/wt lrpcr'  EP_PICK     10*1

    #   16  'potential wt/wt'           PIQ         002*
    #   17  'potential tm1/wt'          PIQ         111*
    #   18  'potential tm1/wt lrpcr'    PIQ         11*1
    #   19  'potential tm1.1/wt'        PIQ         101*
    #   20  'potential tm1.1/wt lrpcr'  PIQ         10*1
  
    #   21  'unknown'
    #   22  'failed: Cre assay validation: Copy Number not present'
    #   23  'failed: Cre assay validation: Copy Number Range not present'
    #   24  'failed: Cre assay validation: Copy Number Range above threshold'
    #   25  'failed: loadel assay validation: Copy Number not present'
    #   26  'failed: loadel assay validation: Copy Number Range not present'
    #   27  'failed: loadel assay validation: Copy Number Range above threshold'
    #   28  'failed: Puro assay validation: Copy Number not present'
    #   29  'failed: Puro assay validation: Copy Number Range not present'
    #   30  'failed: Puro assay validation: Copy Number Range above threshold'
    #   31  'failed: LRPCR assay validation: gr3 primer not present'

    # check each allele type returned matches the expected types
    note('Testing AlleleDetermination Logic - 6c - checking CreKiDre workflow allele types');

    my $crekidre_gc_allele_results = {};
    foreach my $crekidre_well_result_hash ( @{ $crekidre_gc_allele_results_array } ) {
        $crekidre_gc_allele_results->{ $crekidre_well_result_hash->{ 'id' } } = $crekidre_well_result_hash;
    }

    print "crekidre_gc_allele_results:\n";
    print Dumper ( $crekidre_gc_allele_results );

    ok $crekidre_gc_allele_results->{ '1' }->{ 'allele_determination' }  eq 'wt/wt', 'well 1 should be allele type < wt/wt > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '1' }->{ 'genotyping_pass' } eq 'fail', 'well 1 should be an EP_PICK genotyping pass failure as not wanted genotype';
    ok $crekidre_gc_allele_results->{ '2' }->{ 'allele_determination' }  eq 'tm1/wt', 'well 2 should be allele type < tm1/wt > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '3' }->{ 'allele_determination' }  eq 'tm1/wt lrpcr only', 'well 3 should be allele type < tm1/wt lrpcr only > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '4' }->{ 'allele_determination' }  eq 'tm1.1/wt', 'well 4 should be allele type < tm1.1/wt > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '4' }->{ 'genotyping_pass' } eq 'pass', 'well 4 should be an EP_PICK genotyping pass';
    ok $crekidre_gc_allele_results->{ '5' }->{ 'allele_determination' }  eq 'tm1.1/wt lrpcr only', 'well 5 should be allele type < tm1.1/wt lrpcr only > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '5' }->{ 'genotyping_pass' } eq 'pass', 'well 5 should be an EP_PICK genotyping pass';

    ok $crekidre_gc_allele_results->{ '6' }->{ 'allele_determination' }  eq 'wt/wt', 'well 6 should be allele type < wt/wt > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '6' }->{ 'genotyping_pass' } eq 'fail', 'well 6 should be a PIQ genotyping pass failure as not wanted genotype';
    ok $crekidre_gc_allele_results->{ '7' }->{ 'allele_determination' }  eq 'tm1/wt', 'well 7 should be allele type < tm1/wt > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '8' }->{ 'allele_determination' }  eq 'tm1/wt lrpcr only', 'well 8 should be allele type < tm1/wt lrpcr only > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '9' }->{ 'allele_determination' }  eq 'tm1.1/wt', 'well 9 should be allele type < tm1.1/wt > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '9' }->{ 'genotyping_pass' } eq 'fail', 'well 9 should be a PIQ genotyping pass';
    ok $crekidre_gc_allele_results->{ '10' }->{ 'allele_determination' } eq 'tm1.1/wt lrpcr only', 'well 10 should be allele type < tm1.1/wt lrpcr only > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '10' }->{ 'genotyping_pass' } eq 'fail', 'well 10 should be a PIQ genotyping pass (lrpcr)';
    
    ok $crekidre_gc_allele_results->{ '11' }->{ 'allele_determination' } eq 'potential wt/wt', 'well 11 should be allele type < potential wt/wt > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '12' }->{ 'allele_determination' } eq 'potential tm1/wt', 'well 12 should be allele type < potential tm1/wt > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '13' }->{ 'allele_determination' } eq 'potential tm1/wt lrpcr only', 'well 13 should be allele type < potential tm1/wt lrpcr only > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '14' }->{ 'allele_determination' } eq 'potential tm1.1/wt', 'well 14 should be allele type < potential tm1.1/wt > for stage EP_PICK';
    ok $crekidre_gc_allele_results->{ '15' }->{ 'allele_determination' } eq 'potential tm1.1/wt lrpcr only', 'well 15 should be allele type < potential tm1.1/wt lrpcr only > for stage EP_PICK';

    ok $crekidre_gc_allele_results->{ '16' }->{ 'allele_determination' } eq 'potential wt/wt', 'well 16 should be allele type < potential wt/wt > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '17' }->{ 'allele_determination' } eq 'potential tm1/wt', 'well 17 should be allele type < potential tm1/wt > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '18' }->{ 'allele_determination' } eq 'potential tm1/wt lrpcr only', 'well 18 should be allele type < potential tm1/wt lrpcr only > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '19' }->{ 'allele_determination' } eq 'potential tm1.1/wt', 'well 19 should be allele type < potential tm1.1/wt > for stage PIQ';
    ok $crekidre_gc_allele_results->{ '20' }->{ 'allele_determination' } eq 'potential tm1.1/wt lrpcr only', 'well 20 should be allele type < potential tm1.1/wt lrpcr only > for stage PIQ';

    ok $crekidre_gc_allele_results->{ '21' }->{ 'allele_determination' } eq 'Failed: unknown allele pattern : CreKiDre PIQ cre:2.1 puro:2.1 loadel:2.1 gr3:- gf3:- gr4:- gf4:-', 'well 21 should give an unknown allele pattern error';

    ok $crekidre_gc_allele_results->{ '22' }->{ 'allele_determination' } eq 'Failed: validate assays : cre assay validation: Copy Number not present. ',
        'well 22 should give a validation error for missing Cre copy number';
    ok $crekidre_gc_allele_results->{ '23' }->{ 'allele_determination' } eq 'Failed: validate assays : cre assay validation: Copy Number Range not present. ',
        'well 23 should give a validation error for missing Cre copy number range';
    ok $crekidre_gc_allele_results->{ '24' }->{ 'allele_determination' } eq 'Failed: validate assays : cre assay validation: Copy Number Range above threshold. ',
        'well 24 should give a validation error for above threshold Cre copy number range';

    ok $crekidre_gc_allele_results->{ '25' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number not present. lrpcr assay validation: gf3 value not present. ',
        'well 25 should give a validation error for missing loadel copy number and no lrprc results';
    ok $crekidre_gc_allele_results->{ '26' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number Range not present. lrpcr assay validation: gf3 value not present. ',
        'well 26 should give a validation error for missing loadel copy number range and no lrprc results';
    ok $crekidre_gc_allele_results->{ '27' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number Range above threshold. lrpcr assay validation: gf3 value not present. ',
        'well 27 should give a validation error for above threshold loadel copy number range and no lrprc results';

    ok $crekidre_gc_allele_results->{ '28' }->{ 'allele_determination' } eq 'Failed: validate assays : puro assay validation: Copy Number not present. ',
        'well 28 should give a validation error for missing Puro copy number';
    ok $crekidre_gc_allele_results->{ '29' }->{ 'allele_determination' } eq 'Failed: validate assays : puro assay validation: Copy Number Range not present. ',
        'well 29 should give a validation error for missing Puro copy number range';
    ok $crekidre_gc_allele_results->{ '30' }->{ 'allele_determination' } eq 'Failed: validate assays : puro assay validation: Copy Number Range above threshold. ',
        'well 30 should give a validation error for above threshold Puro copy number range';
 
    ok $crekidre_gc_allele_results->{ '31' }->{ 'allele_determination' } eq 'Failed: validate assays : loadel assay validation: Copy Number Range above threshold. lrpcr assay validation: gf3 value not present. ',
        'well 31 should give an LRPCR error for gf3';

    ok $crekidre_gc_allele_results->{ '32' }->{ 'genotyping_pass' } eq 'passb_chr8a', 'well 32 should be a PIQ genotyping passb_chr8a';

    note('Testing AlleleDetermination Logic - Complete');
}

=head1 AUTHOR

Andrew Sparkes

=cut

## use critic

1;

__END__
