package LIMS2::t::Model::Util::AlleleDetermination;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::AlleleDetermination;
use LIMS2::Test;
use strict;

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

sub all_tests : Test(129) {
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
    ok my $ne1a_gc_allele_types = $ne1a_AD->test_determine_allele_types_logic(),
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

    ok $ne1a_gc_allele_types->{'1'} eq 'wt/wt',   'well 1 should be allele type < wt/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_types->{'2'} eq 'tm1a/wt', 'well 2 should be allele type < tm1a/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_types->{'3'} eq 'tm1e/wt', 'well 3 should be allele type < tm1e/wt > for stage EP_PICK';

    ok $ne1a_gc_allele_types->{'4'} eq 'wt/wt',    'well 4 should be allele type < wt/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'5'} eq 'tm1a/wt',  'well 5 should be allele type < tm1a/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'6'} eq 'tm1e/wt',  'well 6 should be allele type < tm1e/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'7'} eq 'wt/tm1',   'well 7 should be allele type < wt/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'8'} eq 'tm1e/tm1', 'well 8 should be allele type < tm1e/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'9'} eq 'tm1a/tm1', 'well 9 should be allele type < tm1a/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'10'} eq 'tm1a/wt+bsd_offtarg',
        'well 10 should be allele type < tm1a/wt+bsd_offtarg > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'11'} eq 'wt+neo_offtarg/tm1',
        'well 11 should be allele type < wt+neo_offtarg/tm1 > for stage SEP_PICK';

    ok $ne1a_gc_allele_types->{'12'} eq 'potential wt/wt',
        'well 12 should be allele type < potential wt/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_types->{'13'} eq 'potential tm1a/wt',
        'well 13 should be allele type < potential tm1a/wt > for stage EP_PICK';
    ok $ne1a_gc_allele_types->{'14'} eq 'potential tm1e/wt',
        'well 14 should be allele type < potential tm1e/wt > for stage EP_PICK';

    ok $ne1a_gc_allele_types->{'15'} eq 'potential wt/wt',
        'well 15 should be allele type < potential wt/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'16'} eq 'potential tm1a/wt',
        'well 16 should be allele type < potential tm1a/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'17'} eq 'potential tm1e/wt',
        'well 17 should be allele type < potential tm1e/wt > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'18'} eq 'potential wt/tm1',
        'well 18 should be allele type < potential wt/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'19'} eq 'potential tm1e/tm1',
        'well 19 should be allele type < potential tm1e/tm1 > for stage SEP_PICK';
    ok $ne1a_gc_allele_types->{'20'} eq 'potential tm1a/tm1',
        'well 20 should be allele type < potential tm1a/tm1 > for stage SEP_PICK';

    ok $ne1a_gc_allele_types->{'21'} eq
        'Failed: unknown allele pattern : Ne1a SEP_PICK bsd<1.1> loacrit<1.1> loadel<1.1> loatam<0.1> neo<1.1>',
        'well 21 should give an unknown allele pattern error';

    ok $ne1a_gc_allele_types->{'22'} eq 'Failed: validate assays : loacrit assay validation: Copy Number not present',
        'well 22 should give a validation error for missing loacrit copy number';
    ok $ne1a_gc_allele_types->{'23'} eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range not present',
        'well 23 should give a validation error for missing loacrit copy number range';
    ok $ne1a_gc_allele_types->{'24'} eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range above threshold',
        'well 24 should give a validation error for above threshold loacrit copy number range';

    ok $ne1a_gc_allele_types->{'25'} eq 'Failed: validate assays : loatam assay validation: Copy Number not present',
        'well 25 should give a validation error for missing loatam copy number';
    ok $ne1a_gc_allele_types->{'26'} eq
        'Failed: validate assays : loatam assay validation: Copy Number Range not present',
        'well 26 should give a validation error for missing loatam copy number range';
    ok $ne1a_gc_allele_types->{'27'} eq
        'Failed: validate assays : loatam assay validation: Copy Number Range above threshold',
        'well 27 should give a validation error for above threshold loatam copy number range';

    ok $ne1a_gc_allele_types->{'28'} eq 'Failed: validate assays : loadel assay validation: Copy Number not present',
        'well 28 should give a validation error for missing loadel copy number';
    ok $ne1a_gc_allele_types->{'29'} eq
        'Failed: validate assays : loadel assay validation: Copy Number Range not present',
        'well 29 should give a validation error for missing loadel copy number range';
    ok $ne1a_gc_allele_types->{'30'} eq
        'Failed: validate assays : loadel assay validation: Copy Number Range above threshold',
        'well 30 should give a validation error for above threshold loadel copy number range';

    ok $ne1a_gc_allele_types->{'31'} eq 'Failed: validate assays : neo assay validation: Copy Number not present',
        'well 31 should give a validation error for missing neo copy number';
    ok $ne1a_gc_allele_types->{'32'} eq 'Failed: validate assays : neo assay validation: Copy Number Range not present',
        'well 32 should give a validation error for missing neo copy number range';
    ok $ne1a_gc_allele_types->{'33'} eq
        'Failed: validate assays : neo assay validation: Copy Number Range above threshold',
        'well 33 should give a validation error for above threshold neo copy number range';

    ok $ne1a_gc_allele_types->{'34'} eq 'Failed: validate assays : bsd assay validation: Copy Number not present',
        'well 34 should give a validation error for missing bsd copy number';
    ok $ne1a_gc_allele_types->{'35'} eq 'Failed: validate assays : bsd assay validation: Copy Number Range not present',
        'well 35 should give a validation error for missing bsd copy number range';
    ok $ne1a_gc_allele_types->{'36'} eq
        'Failed: validate assays : bsd assay validation: Copy Number Range above threshold',
        'well 36 should give a validation error for above threshold bsd copy number range';

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
    ok my $ne1_gc_allele_types = $ne1_AD->test_determine_allele_types_logic(),
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

    ok $ne1_gc_allele_types->{'1'} eq 'wt/wt',  'well 1 should be allele type < wt/wt > for stage EP_PICK';
    ok $ne1_gc_allele_types->{'2'} eq 'tm1/wt', 'well 2 should be allele type < tm1/wt > for stage EP_PICK';

    ok $ne1_gc_allele_types->{'3'} eq 'wt/wt',    'well 3 should be allele type < wt/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'4'} eq 'tm1/wt',   'well 4 should be allele type < tm1/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'5'} eq 'tm1/tm1a', 'well 5 should be allele type < tm1/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'6'} eq 'wt/tm1a',  'well 6 should be allele type < wt/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'7'} eq 'tm1/tm1e', 'well 7 should be allele type < tm1/tm1e > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'8'} eq 'wt/tm1e',  'well 8 should be allele type < wt/tm1e > for stage SEP_PICK';

    ok $ne1_gc_allele_types->{'9'} eq 'potential wt/wt',
        'well 9 should be allele type < potential wt/wt > for stage EP_PICK';
    ok $ne1_gc_allele_types->{'10'} eq 'potential tm1/wt',
        'well 10 should be allele type < potential tm1/wt > for stage EP_PICK';

    ok $ne1_gc_allele_types->{'11'} eq 'potential wt/wt',
        'well 11 should be allele type < potential wt/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'12'} eq 'potential tm1/wt',
        'well 12 should be allele type < potential tm1/wt > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'13'} eq 'potential tm1/tm1a',
        'well 13 should be allele type < potential tm1/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'14'} eq 'potential wt/tm1a',
        'well 14 should be allele type < potential wt/tm1a > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'15'} eq 'potential tm1/tm1e',
        'well 15 should be allele type < potential tm1/tm1e > for stage SEP_PICK';
    ok $ne1_gc_allele_types->{'16'} eq 'potential wt/tm1e',
        'well 16 should be allele type < potential wt/tm1e > for stage SEP_PICK';

    ok $ne1_gc_allele_types->{'17'} eq
        'Failed: unknown allele pattern : Ne1 SEP_PICK bsd<1.1> loacrit<1.1> loadel<1.1> loatam<0.1> neo<1.1>',
        'well 17 should give an unknown allele pattern error';

    ok $ne1_gc_allele_types->{'18'} eq 'Failed: validate assays : loacrit assay validation: Copy Number not present',
        'well 18 should give a validation error for missing loacrit copy number';
    ok $ne1_gc_allele_types->{'19'} eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range not present',
        'well 19 should give a validation error for missing loacrit copy number range';
    ok $ne1_gc_allele_types->{'20'} eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range above threshold',
        'well 20 should give a validation error for above threshold loacrit copy number range';

    ok $ne1_gc_allele_types->{'21'} eq 'Failed: validate assays : loatam assay validation: Copy Number not present',
        'well 21 should give a validation error for missing loatam copy number';
    ok $ne1_gc_allele_types->{'22'} eq
        'Failed: validate assays : loatam assay validation: Copy Number Range not present',
        'well 22 should give a validation error for missing loatam copy number range';
    ok $ne1_gc_allele_types->{'23'} eq
        'Failed: validate assays : loatam assay validation: Copy Number Range above threshold',
        'well 23 should give a validation error for above threshold loatam copy number range';

    ok $ne1_gc_allele_types->{'24'} eq 'Failed: validate assays : loadel assay validation: Copy Number not present',
        'well 24 should give a validation error for missing loadel copy number';
    ok $ne1_gc_allele_types->{'25'} eq
        'Failed: validate assays : loadel assay validation: Copy Number Range not present',
        'well 25 should give a validation error for missing loadel copy number range';
    ok $ne1_gc_allele_types->{'26'} eq
        'Failed: validate assays : loadel assay validation: Copy Number Range above threshold',
        'well 26 should give a validation error for above threshold loadel copy number range';

    ok $ne1_gc_allele_types->{'27'} eq 'Failed: validate assays : neo assay validation: Copy Number not present',
        'well 27 should give a validation error for missing neo copy number';
    ok $ne1_gc_allele_types->{'28'} eq 'Failed: validate assays : neo assay validation: Copy Number Range not present',
        'well 28 should give a validation error for missing neo copy number range';
    ok $ne1_gc_allele_types->{'29'} eq
        'Failed: validate assays : neo assay validation: Copy Number Range above threshold',
        'well 29 should give a validation error for above threshold neo copy number range';

    ok $ne1_gc_allele_types->{'30'} eq 'Failed: validate assays : bsd assay validation: Copy Number not present',
        'well 30 should give a validation error for missing bsd copy number';
    ok $ne1_gc_allele_types->{'31'} eq 'Failed: validate assays : bsd assay validation: Copy Number Range not present',
        'well 31 should give a validation error for missing bsd copy number range';
    ok $ne1_gc_allele_types->{'32'} eq
        'Failed: validate assays : bsd assay validation: Copy Number Range above threshold',
        'well 32 should give a validation error for above threshold bsd copy number range';

    # fetch workflow E data
    note('Testing AlleleDetermination Logic - step 4a - extracting Essential workflow data');
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
    ok my $e_gc_allele_types = $e_AD->test_determine_allele_types_logic(), 'calculating E allele types should succeed';

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

    ok $e_gc_allele_types->{'1'} eq 'tm1f/wt; wt/wt',
        'well 1 should be allele type < tm1f/wt, wt/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'2'} eq 'tm1a/wt', 'well 2 should be allele type < tm1a/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'3'} eq 'tm1c/wt', 'well 3 should be allele type < tm1c/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'4'} eq 'tm1e/wt', 'well 4 should be allele type < tm1e/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'5'} eq 'tm1f/wt; wt/wt',
        'well 5 should be allele type < tm1f/wt, wt/wt > for stage EP_PICK';

    ok $e_gc_allele_types->{'6'}  eq 'wt/wt',    'well 6 should be allele type < wt/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'7'}  eq 'tm1a/wt',  'well 7 should be allele type < tm1a/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'8'}  eq 'tm1c/wt',  'well 8 should be allele type < tm1c/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'9'}  eq 'tm1e/wt',  'well 9 should be allele type < tm1e/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'10'} eq 'tm1f/wt',  'well 10 should be allele type < tm1f/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'11'} eq 'wt/tm1',   'well 11 should be allele type < wt/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'12'} eq 'tm1a/tm1', 'well 12 should be allele type < tm1a/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'13'} eq 'tm1c/tm1', 'well 13 should be allele type < tm1c/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'14'} eq 'tm1e/tm1', 'well 14 should be allele type < tm1e/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'15'} eq 'tm1f/tm1', 'well 15 should be allele type < tm1f/tm1 > for stage SEP_PICK';

    ok $e_gc_allele_types->{'16'} eq 'potential tm1f/wt; potential wt/wt',
        'well 16 should be allele type < potential tm1f/wt, potential wt/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'17'} eq 'potential tm1a/wt',
        'well 17 should be allele type < potential tm1a/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'18'} eq 'potential tm1c/wt',
        'well 18 should be allele type < potential tm1c/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'19'} eq 'potential tm1e/wt',
        'well 19 should be allele type < potential tm1e/wt > for stage EP_PICK';
    ok $e_gc_allele_types->{'20'} eq 'potential tm1f/wt; potential wt/wt',
        'well 20 should be allele type < potential tm1f/wt, potential wt/wt > for stage EP_PICK';

    ok $e_gc_allele_types->{'21'} eq 'potential wt/wt',
        'well 21 should be allele type < potential wt/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'22'} eq 'potential tm1a/wt',
        'well 22 should be allele type < potential tm1a/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'23'} eq 'potential tm1c/wt',
        'well 23 should be allele type < potential tm1c/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'24'} eq 'potential tm1e/wt',
        'well 24 should be allele type < potential tm1e/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'25'} eq 'potential tm1f/wt',
        'well 25 should be allele type < potential tm1f/wt > for stage SEP_PICK';
    ok $e_gc_allele_types->{'26'} eq 'potential wt/tm1',
        'well 26 should be allele type < potential wt/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'27'} eq 'potential tm1a/tm1',
        'well 27 should be allele type < potential tm1a/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'28'} eq 'potential tm1c/tm1',
        'well 28 should be allele type < potential tm1c/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'29'} eq 'potential tm1e/tm1',
        'well 29 should be allele type < potential tm1e/tm1 > for stage SEP_PICK';
    ok $e_gc_allele_types->{'30'} eq 'potential tm1f/tm1',
        'well 30 should be allele type < potential tm1f/tm1 > for stage SEP_PICK';

    ok $e_gc_allele_types->{'31'} eq
        'Failed: unknown allele pattern : E SEP_PICK bsd<1.1> loacrit<1.1> loadel<1.1> loatam<0.1> neo<1.1>',
        'well 31 should give an unknown allele pattern error';

    ok $e_gc_allele_types->{'32'} eq 'Failed: validate assays : loacrit assay validation: Copy Number not present',
        'well 32 should give a validation error for missing loacrit copy number';
    ok $e_gc_allele_types->{'33'} eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range not present',
        'well 33 should give a validation error for missing loacrit copy number range';
    ok $e_gc_allele_types->{'34'} eq
        'Failed: validate assays : loacrit assay validation: Copy Number Range above threshold',
        'well 34 should give a validation error for above threshold loacrit copy number range';

    ok $e_gc_allele_types->{'35'} eq 'Failed: validate assays : loatam assay validation: Copy Number not present',
        'well 35 should give a validation error for missing loatam copy number';
    ok $e_gc_allele_types->{'36'} eq 'Failed: validate assays : loatam assay validation: Copy Number Range not present',
        'well 36 should give a validation error for missing loatam copy number range';
    ok $e_gc_allele_types->{'37'} eq
        'Failed: validate assays : loatam assay validation: Copy Number Range above threshold',
        'well 37 should give a validation error for above threshold loatam copy number range';

    ok $e_gc_allele_types->{'38'} eq 'Failed: validate assays : loadel assay validation: Copy Number not present',
        'well 38 should give a validation error for missing loadel copy number';
    ok $e_gc_allele_types->{'39'} eq 'Failed: validate assays : loadel assay validation: Copy Number Range not present',
        'well 39 should give a validation error for missing loadel copy number range';
    ok $e_gc_allele_types->{'40'} eq
        'Failed: validate assays : loadel assay validation: Copy Number Range above threshold',
        'well 40 should give a validation error for above threshold loadel copy number range';

    ok $e_gc_allele_types->{'41'} eq 'Failed: validate assays : neo assay validation: Copy Number not present',
        'well 41 should give a validation error for missing neo copy number';
    ok $e_gc_allele_types->{'42'} eq 'Failed: validate assays : neo assay validation: Copy Number Range not present',
        'well 42 should give a validation error for missing neo copy number range';
    ok $e_gc_allele_types->{'43'} eq
        'Failed: validate assays : neo assay validation: Copy Number Range above threshold',
        'well 43 should give a validation error for above threshold neo copy number range';

    ok $e_gc_allele_types->{'44'} eq 'Failed: validate assays : bsd assay validation: Copy Number not present',
        'well 44 should give a validation error for missing bsd copy number';
    ok $e_gc_allele_types->{'45'} eq 'Failed: validate assays : bsd assay validation: Copy Number Range not present',
        'well 45 should give a validation error for missing bsd copy number range';
    ok $e_gc_allele_types->{'46'} eq
        'Failed: validate assays : bsd assay validation: Copy Number Range above threshold',
        'well 46 should give a validation error for above threshold bsd copy number range';

    note('Testing AlleleDetermination Logic - Complete');
}

=head1 AUTHOR

Andrew Sparkes

=cut

## use critic

1;

__END__
