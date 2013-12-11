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

sub all_tests : Test(275) {
    ok( 1, "Test of LIMS2::Model::Util::CreKiESDistribution" );

    note('Testing CreKiESDistribution Logic - step 1 - loading test data from yaml file');

    ok my $test_data = test_data('10_LIMS2_Model_Util_CreKiESDistribution.yaml'),
        'fetching test data yaml file should succeed';

    # fetch cre ki data hash
    note('Testing CreKiESDistribution Logic - step 2 - extracting test hash');
    ok my $cre_ki_yaml_data = $test_data->{'cre_ki_data'}, 'fetching cre ki data from yaml should succeed';

    # print "Yaml data: \n";
    # print ( Dumper ( $cre_ki_yaml_data ) );

    # Create a new connection Model to link to DB
    ok my $model = LIMS2::Model->new( 'user' => 'tests' ), 'creating a new DB model connection should succeed';

    # Create CreKiESDistribution module instance
    ok my $creKiES_summary_module = LIMS2::Model::Util::CreKiESDistribution->new( 'model' => $model, 'species' => 'Mouse' ),
        'creating instance of module should succeed';

    # Set the cre ki data hash in the module instance
    ok $creKiES_summary_module->cre_ki_genes( $cre_ki_yaml_data ), 'setting cre ki data hash in module instance should succeed';

    note('Testing CreKiESDistribution Logic - step 3 - creating overall summary report and testing content');

    # create report data for the overall summary report page
    $creKiES_summary_module->generate_summary_report_data();

    # fetch the report data
    ok my $summary_report_data = $creKiES_summary_module->report_data;

    # print "Summary report data: \n";
    # print ( Dumper ( $summary_report_data ) );

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

    ok $summary_report_data->[1]->[0]  eq 'Unassigned', 'production centre name should be Unassigned';
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

    # Create CreKiESDistribution module instance
    ok my $creKiES_genes_module = LIMS2::Model::Util::CreKiESDistribution->new( 'model' => $model, 'species' => 'Mouse' ),
        'creating instance of module should succeed';

    # Set the cre ki data hash in the module instance
    ok $creKiES_genes_module->cre_ki_genes( $cre_ki_yaml_data ), 'setting cre ki data hash in module instance should succeed';

    note('Testing CreKiESDistribution Logic - step 5 - creating genes summary report and testing content');

    # create report data for the overall summary report page
    $creKiES_genes_module->generate_genes_report_data();

    # fetch the report data
    ok my $genes_report_data = $creKiES_genes_module->report_data;

    # print "Gene report data: \n";
    # print ( Dumper ( $genes_report_data ) );

    # run tests to check the report data is as expected
    ok $genes_report_data->[0]->[3]  eq 'MGI:1000004', 'gene ID should be MGI:1000004';
    ok $genes_report_data->[0]->[4]  eq 'AwaitVects', 'marker symbol should be AwaitVects';
    ok $genes_report_data->[0]->[2]  eq 'awaiting_vectors', 'basket name should be awaiting_vectors';
    ok $genes_report_data->[0]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[0]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';

    ok $genes_report_data->[1]->[3]  eq 'MGI:1000005', 'gene ID should be MGI:1000005';
    ok $genes_report_data->[1]->[4]  eq 'AwaitEP', 'marker symbol should be AwaitEP';
    ok $genes_report_data->[1]->[2]  eq 'awaiting_electroporation', 'basket name should be awaiting_electroporation';
    ok $genes_report_data->[1]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[1]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[1]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';

    ok $genes_report_data->[2]->[3]  eq 'MGI:1000006', 'gene ID should be MGI:1000006';
    ok $genes_report_data->[2]->[4]  eq 'AwaitPQC', 'marker symbol should be AwaitPQC';
    ok $genes_report_data->[2]->[2]  eq 'awaiting_primary_qc', 'basket name should be awaiting_primary_qc';
    ok $genes_report_data->[2]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[2]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[2]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[2]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    
    ok $genes_report_data->[3]->[3]  eq 'MGI:1000007', 'gene ID should be MGI:1000007';
    ok $genes_report_data->[3]->[4]  eq 'InPQC', 'marker symbol should be InPQC';
    ok $genes_report_data->[3]->[2]  eq 'in_primary_qc', 'basket name should be in_primary_qc';
    ok $genes_report_data->[3]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[3]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[3]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[3]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02', 'accepted clone well ids should be CEPD0001_1_A01 : CEPD0001_1_A02';
    ok $genes_report_data->[3]->[7]  eq 'CEPD0001_1_A02', 'failed clone well ids should be CEPD0001_1_A02';
    
    ok $genes_report_data->[4]->[3]  eq 'MGI:1000008', 'gene ID should be MGI:1000008';
    ok $genes_report_data->[4]->[4]  eq 'FailPQC', 'marker symbol should be FailPQC';
    ok $genes_report_data->[4]->[2]  eq 'failed_primary_qc_no_rem_clones', 'basket name should be failed_primary_qc_no_rem_clones';
    ok $genes_report_data->[4]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[4]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[4]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[4]->[6]  eq '', 'should be no accepted clone well ids';
    ok $genes_report_data->[4]->[7]  eq 'CEPD0001_1_A01', 'failed clone well ids should be CEPD0001_1_A01';

    ok $genes_report_data->[5]->[3]  eq 'MGI:1000009', 'gene ID should be MGI:1000009';
    ok $genes_report_data->[5]->[4]  eq 'AwaitSQC', 'marker symbol should be AwaitSQC';
    ok $genes_report_data->[5]->[2]  eq 'awaiting_secondary_qc', 'basket name should be awaiting_secondary_qc';
    ok $genes_report_data->[5]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[5]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[5]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[5]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';

    ok $genes_report_data->[6]->[3]  eq 'MGI:1000010', 'gene ID should be MGI:1000010';
    ok $genes_report_data->[6]->[4]  eq 'InSQC1', 'marker symbol should be InSQC1';
    ok $genes_report_data->[6]->[2]  eq 'in_secondary_qc_1_clone', 'basket name should be in_secondary_qc_1_clone';
    ok $genes_report_data->[6]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[6]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[6]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[6]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';

    ok $genes_report_data->[7]->[3]  eq 'MGI:1000011', 'gene ID should be MGI:1000011';
    ok $genes_report_data->[7]->[4]  eq 'InSQC2', 'marker symbol should be InSQC2';
    ok $genes_report_data->[7]->[2]  eq 'in_secondary_qc_2_clones', 'basket name should be in_secondary_qc_2_clones';
    ok $genes_report_data->[7]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[7]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[7]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[7]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02', 'accepted clone well ids should be CEPD0001_1_A01 : CEPD0001_1_A02';

    ok $genes_report_data->[8]->[3]  eq 'MGI:1000012', 'gene ID should be MGI:1000012';
    ok $genes_report_data->[8]->[4]  eq 'InSQC3', 'marker symbol should be InSQC3';
    ok $genes_report_data->[8]->[2]  eq 'in_secondary_qc_3_clones', 'basket name should be in_secondary_qc_3_clones';
    ok $genes_report_data->[8]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[8]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[8]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[8]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03', 'accepted clone well ids should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03';

    ok $genes_report_data->[9]->[3]  eq 'MGI:1000013', 'gene ID should be MGI:1000013';
    ok $genes_report_data->[9]->[4]  eq 'InSQC4', 'marker symbol should be InSQC4';
    ok $genes_report_data->[9]->[2]  eq 'in_secondary_qc_4_clones', 'basket name s4ould be in_secondary_qc_4_clones';
    ok $genes_report_data->[9]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[9]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[9]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[9]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04', 'accepted clone well ids should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04';

    ok $genes_report_data->[10]->[3]  eq 'MGI:1000014', 'gene ID should be MGI:1000014';
    ok $genes_report_data->[10]->[4]  eq 'InSQC5', 'marker symbol should be InSQC5';
    ok $genes_report_data->[10]->[2]  eq 'in_secondary_qc_5_clones', 'basket name s4ould be in_secondary_qc_5_clones';
    ok $genes_report_data->[10]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[10]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[10]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[10]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05', 'accepted clone well ids should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05';

    ok $genes_report_data->[11]->[3]  eq 'MGI:1000015', 'gene ID should be MGI:1000015';
    ok $genes_report_data->[11]->[4]  eq 'InSQCgt5', 'marker symbol should be InSQCgt5';
    ok $genes_report_data->[11]->[2]  eq 'in_secondary_qc_gt5_clones', 'basket name s4ould be in_secondary_qc_gt5_clones';
    ok $genes_report_data->[11]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[11]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[11]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[11]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05 : CEPD0001_1_A06', 'accepted clone well ids should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05 : CEPD0001_1_A06';

    ok $genes_report_data->[12]->[3]  eq 'MGI:1000016', 'gene ID should be MGI:1000016';
    ok $genes_report_data->[12]->[4]  eq 'FailSQC1', 'marker symbol should be FailSQC1';
    ok $genes_report_data->[12]->[2]  eq 'failed_secondary_qc_1_clone', 'basket name should be failed_secondary_qc_1_clone';
    ok $genes_report_data->[12]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[12]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[12]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[12]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    ok $genes_report_data->[12]->[9]  eq 'CEPD0001_1_A01', 'failed secondary QC clone list should be CEPD0001_1_A01';

    ok $genes_report_data->[13]->[3]  eq 'MGI:1000017', 'gene ID should be MGI:1000017';
    ok $genes_report_data->[13]->[4]  eq 'FailSQC2', 'marker symbol should be FailSQC2';
    ok $genes_report_data->[13]->[2]  eq 'failed_secondary_qc_2_clones', 'basket name should be failed_secondary_qc_2_clones';
    ok $genes_report_data->[13]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[13]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[13]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[13]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02', 'accepted clone well id should be CEPD0001_1_A01 : CEPD0001_1_A02';
    ok $genes_report_data->[13]->[9]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02', 'failed secondary QC clone list should be CEPD0001_1_A01 : CEPD0001_1_A02';

    ok $genes_report_data->[14]->[3]  eq 'MGI:1000018', 'gene ID should be MGI:1000018';
    ok $genes_report_data->[14]->[4]  eq 'FailSQC3', 'marker symbol should be FailSQC3';
    ok $genes_report_data->[14]->[2]  eq 'failed_secondary_qc_3_clones', 'basket name should be failed_secondary_qc_3_clones';
    ok $genes_report_data->[14]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[14]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[14]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[14]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03', 'accepted clone well id should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03';
    ok $genes_report_data->[14]->[9]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03', 'failed secondary QC clone list should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03';

    ok $genes_report_data->[15]->[3]  eq 'MGI:1000019', 'gene ID should be MGI:1000019';
    ok $genes_report_data->[15]->[4]  eq 'FailSQC4', 'marker symbol should be FailSQC4';
    ok $genes_report_data->[15]->[2]  eq 'failed_secondary_qc_4_clones', 'basket name should be failed_secondary_qc_4_clones';
    ok $genes_report_data->[15]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[15]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[15]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[15]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04', 'accepted clone well id should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04';
    ok $genes_report_data->[15]->[9]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04', 'failed secondary QC clone list should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04';

    ok $genes_report_data->[16]->[3]  eq 'MGI:1000020', 'gene ID should be MGI:1000020';
    ok $genes_report_data->[16]->[4]  eq 'FailSQC5', 'marker symbol should be FailSQC5';
    ok $genes_report_data->[16]->[2]  eq 'failed_secondary_qc_5_clones', 'basket name should be failed_secondary_qc_5_clones';
    ok $genes_report_data->[16]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[16]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[16]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[16]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05', 'accepted clone well id should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05';
    ok $genes_report_data->[16]->[9]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05', 'failed secondary QC clone list should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05';

    ok $genes_report_data->[17]->[3]  eq 'MGI:1000021', 'gene ID should be MGI:1000021';
    ok $genes_report_data->[17]->[4]  eq 'FailSQCgt5', 'marker symbol should be FailSQCgt5';
    ok $genes_report_data->[17]->[2]  eq 'failed_secondary_qc_gt5_clones', 'basket name should be failed_secondary_qc_gt5_clones';
    ok $genes_report_data->[17]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[17]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[17]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[17]->[6]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05 : CEPD0001_1_A06', 'accepted clone well id should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05 : CEPD0001_1_A06';
    ok $genes_report_data->[17]->[9]  eq 'CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05 : CEPD0001_1_A06', 'failed secondary QC clone list should be CEPD0001_1_A01 : CEPD0001_1_A02 : CEPD0001_1_A03 : CEPD0001_1_A04 : CEPD0001_1_A05 : CEPD0001_1_A06';

    ok $genes_report_data->[18]->[3]  eq 'MGI:1000022', 'gene ID should be MGI:1000022';
    ok $genes_report_data->[18]->[4]  eq 'FailSQCnc', 'marker symbol should be FailSQCnc';
    ok $genes_report_data->[18]->[2]  eq 'failed_secondary_qc_no_rem_clones', 'basket name should be failed_secondary_qc_no_rem_clones';
    ok $genes_report_data->[18]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[18]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[18]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[18]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    ok $genes_report_data->[18]->[9]  eq 'CEPD0001_1_A01', 'failed secondary QC clone list should be CEPD0001_1_A01';

    ok $genes_report_data->[19]->[3]  eq 'MGI:1000023', 'gene ID should be MGI:1000023';
    ok $genes_report_data->[19]->[4]  eq 'AwaitMIs', 'marker symbol should be AwaitMIs';
    ok $genes_report_data->[19]->[2]  eq 'awaiting_mi_attempts', 'basket name should be awaiting_mi_attempts';
    ok $genes_report_data->[19]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[19]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[19]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[19]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    ok $genes_report_data->[19]->[8]  eq 'CEPD0001_1_A01', 'passed secondary QC clone list should be CEPD0001_1_A01';

    ok $genes_report_data->[20]->[3]  eq 'MGI:1000025', 'gene ID should be MGI:1000025';
    ok $genes_report_data->[20]->[4]  eq 'FailedMP', 'marker symbol should be FailedMP';
    ok $genes_report_data->[20]->[2]  eq 'mi_attempts_aborted', 'basket name should be mi_attempts_aborted';
    ok $genes_report_data->[20]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[20]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[20]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[20]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    ok $genes_report_data->[20]->[8]  eq 'CEPD0001_1_A01', 'passed secondary QC clone list should be CEPD0001_1_A01';
    ok $genes_report_data->[20]->[10]  eq 'CEPD0001_1_A01', 'MI attempt aborted clone list should be CEPD0001_1_A01';
    
    ok $genes_report_data->[21]->[3]  eq 'MGI:1000024', 'gene ID should be MGI:1000024';
    ok $genes_report_data->[21]->[4]  eq 'InProgress', 'marker symbol should be InProgress';
    ok $genes_report_data->[21]->[2]  eq 'mi_attempts_in_progress', 'basket name should be mi_attempts_in_progress';
    ok $genes_report_data->[21]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[21]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[21]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[21]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    ok $genes_report_data->[21]->[8]  eq 'CEPD0001_1_A01', 'passed secondary QC clone list should be CEPD0001_1_A01';
    ok $genes_report_data->[21]->[11]  eq 'CEPD0001_1_A01', 'MI attempt in progress clone list should be CEPD0001_1_A01';
    
    ok $genes_report_data->[22]->[3]  eq 'MGI:1000026', 'gene ID should be MGI:1000026';
    ok $genes_report_data->[22]->[4]  eq 'Chimeras', 'marker symbol should be Chimeras';
    ok $genes_report_data->[22]->[2]  eq 'mi_attempts_chimeras_obtained', 'basket name should be mi_attempts_chimeras_obtained';
    ok $genes_report_data->[22]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[22]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[22]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[22]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    ok $genes_report_data->[22]->[8]  eq 'CEPD0001_1_A01', 'passed secondary QC clone list should be CEPD0001_1_A01';
    ok $genes_report_data->[22]->[12]  eq 'CEPD0001_1_A01', 'MI attempt chimeras clone list should be CEPD0001_1_A01';
    
    ok $genes_report_data->[23]->[3]  eq 'MGI:1000027', 'gene ID should be MGI:1000027';
    ok $genes_report_data->[23]->[4]  eq 'GltAchv', 'marker symbol should be GltAchv';
    ok $genes_report_data->[23]->[2]  eq 'mi_attempts_glt_achieved', 'basket name should be mi_attempts_glt_achieved';
    ok $genes_report_data->[23]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[23]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[23]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[23]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';
    ok $genes_report_data->[23]->[8]  eq 'CEPD0001_1_A01', 'passed secondary QC clone list should be CEPD0001_1_A01';
    ok $genes_report_data->[23]->[13]  eq 'CEPD0001_1_A01', 'MI attempt genotype confirmed clone list should be CEPD0001_1_A01';

    ok $genes_report_data->[24]->[3]  eq 'MGI:1000028', 'gene ID should be MGI:1000028';
    ok $genes_report_data->[24]->[4]  eq 'MissLims2', 'marker symbol should be MissLims2';
    ok $genes_report_data->[24]->[2]  eq 'missing_from_lims2', 'basket name should be missing_from_lims2';
    ok $genes_report_data->[24]->[0]  eq 'WTSI', 'production centre name should be WTSI';
    ok $genes_report_data->[24]->[1]  eq 'WTSI_Low', 'production centre priority should be WTSI_Low';
    ok $genes_report_data->[24]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';

    ok $genes_report_data->[25]->[3]  eq 'MGI:1000001', 'gene ID should be MGI:1000001';
    ok $genes_report_data->[25]->[4]  eq 'Unreq', 'marker symbol should be Unreq';
    ok $genes_report_data->[25]->[2]  eq 'unrequested', 'basket name should be unrequested';
    ok $genes_report_data->[25]->[0]  eq 'Unassigned', 'production centre name should be Unassigned';

    ok $genes_report_data->[26]->[3]  eq 'MGI:1000002', 'gene ID should be MGI:1000002';
    ok $genes_report_data->[26]->[4]  eq 'UnreqVect', 'marker symbol should be UnreqVect';
    ok $genes_report_data->[26]->[2]  eq 'unrequested_vector_complete', 'basket name should be unrequested_vector_complete';
    ok $genes_report_data->[26]->[0]  eq 'Unassigned', 'production centre name should be Unassigned';

    ok $genes_report_data->[27]->[3]  eq 'MGI:1000003', 'gene ID should be MGI:1000003';
    ok $genes_report_data->[27]->[4]  eq 'UnreqClones', 'marker symbol should be UnreqClones';
    ok $genes_report_data->[27]->[2]  eq 'unrequested_has_clones', 'basket name should be unrequested_has_clones';
    ok $genes_report_data->[27]->[0]  eq 'Unassigned', 'production centre name should be Unassigned';
    ok $genes_report_data->[27]->[5]  eq 'ETGRD0001_A_1_A01', 'vector well id should be ETGRD0001_A_1_A01';
    ok $genes_report_data->[27]->[6]  eq 'CEPD0001_1_A01', 'accepted clone well id should be CEPD0001_1_A01';

    note('Testing CreKiESDistribution Logic - Testing complete');
}

=head1 AUTHOR

Andrew Sparkes

=cut

## use critic

1;

__END__
