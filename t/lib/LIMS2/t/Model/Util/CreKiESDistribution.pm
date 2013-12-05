package LIMS2::t::Model::Util::CreKiESDistribution;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::CreKiESDistribution;
use LIMS2::Test;
use strict;

use Data::Dumper;

## no critic

=head1 NAME

LIMS2/t/Model/Util/CreKiESDistribution.pm - test class for LIMS2::Model::Util::CreKiESDistribution

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

sub all_tests : Test(69) {
    ok( 1, "Test of LIMS2::Model::Util::CreKiESDistribution" );

    note('Testing CreKiESDistribution Logic - step 1 - loading test data from yaml file');

    ok my $test_data = test_data('10_LIMS2_Model_Util_CreKiESDistribution.yaml'),
        'fetching test data yaml file should succeed';

    # fetch cre ki data hash
    note('Testing CreKiESDistribution Logic - step 2 - extracting test hash');
    ok my $cre_ki_yaml_data = $test_data->{'cre_ki_data'}, 'fetching cre ki data from yaml should succeed';

    print "Yaml data: \n";
    print ( Dumper ( $cre_ki_yaml_data ) );

    # Create a new connection Model to link to DB
    ok my $model = LIMS2::Model->new( 'user' => 'tests' ), 'creating a new DB model connection should succeed';

    # Create CreKiESDistribution module instance
    ok my $creKiES_module = LIMS2::Model::Util::CreKiESDistribution->new( 'model' => $model, 'species' => 'Mouse' ),
        'creating instance of module should succeed';

    # Set the cre ki data hash in the module instance
    ok $creKiES_module->cre_ki_genes( $cre_ki_yaml_data ), 'setting cre ki data hash in module instance should succeed';

    note('Testing CreKiESDistribution Logic - step 3 - creating overall summary report and testing content');

    # create report data for the overall summary report page
    $creKiES_module->generate_summary_report_data();

    # fetch the report data
    ok my $summary_report_data = $creKiES_module->report_data;

    print "Summary report data: \n";
    print ( Dumper ( $summary_report_data ) );

    # run tests to check the report data is as expected
    ok $summary_report_data->[0]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $summary_report_data->[0]->[1]  eq '25', 'count of WTSI genes total should be 25';
    ok $summary_report_data->[0]->[2]  eq '0', 'count of WTSI genes unrequested should be 0';
    ok $summary_report_data->[0]->[3]  eq '0', 'count of WTSI genes unrequested vector complete should be 0';
    ok $summary_report_data->[0]->[4]  eq '0', 'count of WTSI genes unrequested has clones should be 0';
    ok $summary_report_data->[0]->[5]  eq '1', 'count of WTSI genes awaiting vectors should be 1';
    ok $summary_report_data->[0]->[6]  eq '1', 'count of WTSI genes awaiting electroporation should be 1';
    ok $summary_report_data->[0]->[7]  eq '1', 'count of WTSI genes awaiting primary qc should be 1';
    ok $summary_report_data->[0]->[8]  eq '1', 'count of WTSI genes in primary qc should be 1';
    ok $summary_report_data->[0]->[9]  eq '1', 'count of WTSI genes failed primary qc should be 1';
    ok $summary_report_data->[0]->[10] eq '1', 'count of WTSI genes awaiting secondary qc should be 1';
    ok $summary_report_data->[0]->[11] eq '1', 'count of WTSI genes in secondary qc 1 clone should be 1';
    ok $summary_report_data->[0]->[12] eq '1', 'count of WTSI genes in secondary qc 2 clones should be 1';
    ok $summary_report_data->[0]->[13] eq '1', 'count of WTSI genes in secondary qc 3 clones should be 1';
    ok $summary_report_data->[0]->[14] eq '1', 'count of WTSI genes in secondary qc 4 clones should be 1';
    ok $summary_report_data->[0]->[15] eq '1', 'count of WTSI genes in secondary qc 5 clones should be 1';
    ok $summary_report_data->[0]->[16] eq '1', 'count of WTSI genes in secondary qc gt5 clones should be 1';
    ok $summary_report_data->[0]->[17] eq '1', 'count of WTSI genes failed secondary qc 1 clone should be 1';
    ok $summary_report_data->[0]->[18] eq '1', 'count of WTSI genes failed secondary qc 2 clones should be 1';
    ok $summary_report_data->[0]->[19] eq '1', 'count of WTSI genes failed secondary qc 3 clones should be 1';
    ok $summary_report_data->[0]->[20] eq '1', 'count of WTSI genes failed secondary qc 4 clones should be 1';
    ok $summary_report_data->[0]->[21] eq '1', 'count of WTSI genes failed secondary qc 5 clones should be 1';
    ok $summary_report_data->[0]->[22] eq '1', 'count of WTSI genes failed secondary qc gt5 clones should be 1';
    ok $summary_report_data->[0]->[23] eq '1', 'count of WTSI genes failed secondary qc no remaining clones should be 1';
    ok $summary_report_data->[0]->[24] eq '1', 'count of WTSI genes awaiting mi attempts should be 1';
    ok $summary_report_data->[0]->[25] eq '1', 'count of WTSI genes in progress active mi attempts should be 1';
    ok $summary_report_data->[0]->[26] eq '1', 'count of WTSI genes failed in mouse production should be 1';
    ok $summary_report_data->[0]->[27] eq '1', 'count of WTSI genes chimeras obtained should be 1';
    ok $summary_report_data->[0]->[28] eq '1', 'count of WTSI genes glt achieved should be 1';
    ok $summary_report_data->[0]->[29] eq '1', 'count of WTSI genes missing from_lims2 should be 1';
    ok $summary_report_data->[0]->[30] eq '0', 'count of WTSI genes unrecognised type should be 0';

    ok $summary_report_data->[1]->[0]  eq 'unassigned', 'production centre name should be unassigned';
    ok $summary_report_data->[1]->[1]  eq '4', 'count of unassigned genes total should be 4';
    ok $summary_report_data->[1]->[2]  eq '1', 'count of unassigned genes unrequested should be 1';
    ok $summary_report_data->[1]->[3]  eq '1', 'count of unassigned genes unrequested vector complete should be 1';
    ok $summary_report_data->[1]->[4]  eq '1', 'count of unassigned genes unrequested has clones should be 1';
    ok $summary_report_data->[1]->[5]  eq '0', 'count of unassigned genes awaiting vectors should be 0';
    ok $summary_report_data->[1]->[6]  eq '0', 'count of unassigned genes awaiting electroporation should be 0';
    ok $summary_report_data->[1]->[7]  eq '0', 'count of unassigned genes awaiting primary qc should be 0';
    ok $summary_report_data->[1]->[8]  eq '0', 'count of unassigned genes in primary qc should be 0';
    ok $summary_report_data->[1]->[9]  eq '0', 'count of unassigned genes failed primary qc should be 0';
    ok $summary_report_data->[1]->[10] eq '0', 'count of unassigned genes awaiting secondary qc should be 0';
    ok $summary_report_data->[1]->[11] eq '0', 'count of unassigned genes in secondary qc 1 clone should be 0';
    ok $summary_report_data->[1]->[12] eq '0', 'count of unassigned genes in secondary qc 2 clones should be 0';
    ok $summary_report_data->[1]->[13] eq '0', 'count of unassigned genes in secondary qc 3 clones should be 0';
    ok $summary_report_data->[1]->[14] eq '0', 'count of unassigned genes in secondary qc 4 clones should be 0';
    ok $summary_report_data->[1]->[15] eq '0', 'count of unassigned genes in secondary qc 5 clones should be 0';
    ok $summary_report_data->[1]->[16] eq '0', 'count of unassigned genes in secondary qc gt5 clones should be 0';
    ok $summary_report_data->[1]->[17] eq '0', 'count of unassigned genes failed secondary qc 1 clone should be 0';
    ok $summary_report_data->[1]->[18] eq '0', 'count of unassigned genes failed secondary qc 2 clones should be 0';
    ok $summary_report_data->[1]->[19] eq '0', 'count of unassigned genes failed secondary qc 3 clones should be 0';
    ok $summary_report_data->[1]->[20] eq '0', 'count of unassigned genes failed secondary qc 4 clones should be 0';
    ok $summary_report_data->[1]->[21] eq '0', 'count of unassigned genes failed secondary qc 5 clones should be 0';
    ok $summary_report_data->[1]->[22] eq '0', 'count of unassigned genes failed secondary qc gt5 clones should be 0';
    ok $summary_report_data->[1]->[23] eq '0', 'count of unassigned genes failed secondary qc no remaining clones should be 0';
    ok $summary_report_data->[1]->[24] eq '0', 'count of unassigned genes awaiting mi attempts should be 0';
    ok $summary_report_data->[1]->[25] eq '0', 'count of unassigned genes in progress active mi attempts should be 0';
    ok $summary_report_data->[1]->[26] eq '0', 'count of unassigned genes failed in mouse production should be 0';
    ok $summary_report_data->[1]->[27] eq '0', 'count of unassigned genes chimeras obtained should be 0';
    ok $summary_report_data->[1]->[28] eq '0', 'count of unassigned genes glt achieved should be 0';
    ok $summary_report_data->[1]->[29] eq '0', 'count of unassigned genes missing from_lims2 should be 0';
    ok $summary_report_data->[1]->[30] eq '1', 'count of unassigned genes unrecognised type should be 1';

    note('Testing CreKiESDistribution Logic - step 4 - creating gene details report and testing content');

    # create report data for the detailed genes report page 
    # $creKiES_module->generate_genes_report_data();

    # # fetch the report data
    # ok my $gene_details_report_data = $creKiES_module->report_data;
    
    # print ( Dumper ( $gene_details_report_data ) );

    # run tests to check the report data is as expected







    # ok $ne1a_gc_allele_results->{ '0' }->{ 'allele_determination' } eq 'wt/wt',   'well 1 should be allele type < wt/wt > for stage EP_PICK';
    

    note('Testing CreKiESDistribution Logic - Testing complete');
}

=head1 AUTHOR

Andrew Sparkes

=cut

## use critic

1;

__END__
