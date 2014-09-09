package LIMS2::t::Model::Util::GenomeBrowser;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::GenomeBrowser qw/
    crisprs_for_region
    crisprs_to_gff
    crispr_pairs_for_region
    crispr_pairs_to_gff
    gibson_designs_for_region
    design_oligos_to_gff
    /;
use LIMS2::Test model => { classname => __PACKAGE__ };

## no critic

=head1 NAME

LIMS2/t/Model/Util/GenomeBrowser.pm - test class for LIMS2::Model::Util::GenomeBrowser

=cut

sub a_test_chromosome_retrieval : Test(2) {
    ok my $chromosome_id =  LIMS2::Model::Util::GenomeBrowser::retrieve_chromosome_id( model->schema, 'Mouse', '7' );
    is $chromosome_id, 3178, 'can retrieve chromosome id';
}

sub b_test_browser_crisprs_for_region : Test(14) {
    my %params = (
        'assembly_id'       => 'GRCm38',
        'chromosome_number' => '7',
        'start_coord'       => '141000000',
        'end_coord'         => '150000000',
        'species'           => 'Mouse',
    );
    ok my $crispr_rs = crisprs_for_region( model->schema, \%params ), 'can retrieve individual crispr resultset for region';
    ok my $test_crispr = $crispr_rs->find( '69848', $params{'assembly_id'} ), 'can get a crispr locus record';
    ok $crispr_rs = crisprs_for_region( model->schema, \%params ), 'can re-run database query';

    is $test_crispr->crispr_id, 69848, 'crispr_id is correct';
    is $test_crispr->assembly_id, 'GRCm38', 'assembly_id is correct';
    is $test_crispr->chr_id, 3178, 'chr_id is correct';
    is $test_crispr->chr_start, '141009904', 'chr_start is correct';
    is $test_crispr->chr_end, '141009926', 'chr_end is correct';
    is $test_crispr->chr_strand, '1', 'chr_strand is correct';

    ok my $test_gff_crisprs =  crisprs_to_gff( $crispr_rs, \%params ), 'converted and returned gff3 format single crispr data';
    is ref $test_gff_crisprs, 'ARRAY', 'result is an array reference';
    is scalar @$test_gff_crisprs, 15, 'Array has the correct number of elements';
    my @example = grep { /ID=Crispr_69848/ } @$test_gff_crisprs;
    is scalar @example, 1, 'Example contains just one example crispr';
    is $example[0],
    "7\tLIMS2\tCDS\t141009904\t141009924\t.\t+\t.\tID=Crispr_69848;Parent=C_69848;Name=LIMS2-69848;color=#45A825",
    'Element 0 is in the correct format';
}

sub c_test_browser_crispr_pairs_for_region : Test(19) {
    my %params = (
        'assembly_id'       => 'GRCm38',
        'chromosome_number' => '7',
        'start_coord'       => '141000000',
        'end_coord'         => '142000000',
        'species'           => 'Mouse',
    );

    ok my $crispr_pairs_rs = crispr_pairs_for_region( model->schema, \%params ), 'can retrieve crispr pairs for chromosome region';
    ok my $test_crispr_pair = $crispr_pairs_rs->find( 4423 ), 'can get a crispr pair record';
    ok $crispr_pairs_rs = crispr_pairs_for_region( model->schema, \%params ), 'can re-run database query';
    is $test_crispr_pair->pair_id , 4423 , 'crispr_pair_id is correct';
    is $test_crispr_pair->left_crispr_id, 69871, 'left_crispr_id is correct';
    is $test_crispr_pair->right_crispr_id, 69848, 'right_crispr_id is correct';
    is $test_crispr_pair->left_crispr_seq, 'CCACCATCTTCCGATCCCTAGAC', 'left_crispr_seq is correct';
    is $test_crispr_pair->right_crispr_seq, 'ATAGACACGGTCAGTGGCCCTGG', 'right_crispr_seq is correct';
    is $test_crispr_pair->left_crispr_start, '141009868', 'left_crispr_start is correct';
    is $test_crispr_pair->right_crispr_start, '141009904', 'right_crispr_start is correct';
    is $test_crispr_pair->left_crispr_end, '141009890', 'left_crispr_end is correct';
    is $test_crispr_pair->right_crispr_end, '141009926', 'right_crispr_end is correct';

    ok my $test_gff_crisprs =  crispr_pairs_to_gff( $crispr_pairs_rs, \%params ), 'converted and returned gff3 format paired crispr data';
    is ref $test_gff_crisprs, 'ARRAY', 'result is an array reference';
    is scalar @$test_gff_crisprs, 8, 'Array has the correct number of elements';
    my @example_pair = grep { /Name=LIMS2-4423/ } @$test_gff_crisprs;
    is scalar @example_pair, 1, 'Example contains just one example crispr pair';
    is $example_pair[0],
    "7\tLIMS2\tcrispr_pair\t141009868\t141009926\t.\t+\t.\tID=4423;Name=LIMS2-4423",
    'Parent element [3] is in the correct format';
    my @crispr_child = grep { /ID=Crispr_69871/ } @$test_gff_crisprs;
    is $crispr_child[0],
    "7\tLIMS2\tCDS\t141009870\t141009890\t.\t+\t.\tID=Crispr_69871;Parent=4423;Name=LIMS2-69871;color=#45A825",
    'Child crispr element is in the correct format';
    my @pam_child = grep { /ID=PAM_69871/ } @$test_gff_crisprs;
    is $pam_child[0],
    "7\tLIMS2\tCDS\t141009868\t141009870\t.\t+\t.\tID=PAM_69871;Parent=4423;Name=LIMS2-69871;color=#1A8599",
    'Child PAM element is in the correct format';
}

sub d_test_gibson_designs_for_region : Test(19) {
    my %params = (
        'assembly_id'       => 'GRCm38',
        'chromosome_number' => '7',
        'start_coord'       => '141009355',
        'end_coord'         => '141010224',
        'species'           => 'Mouse',
    );

    ok my $gibson_design_rs = gibson_designs_for_region( model->schema, \%params ), 'can retrieve gibson design resultset for region';
    ok my $test_gibson = $gibson_design_rs->find( {'oligo_id' => 54813} ), 'can get a gibson design record';
    is $test_gibson->oligo_id, '54813', 'oligo_id is correct';
    is $test_gibson->assembly_id, 'GRCm38', 'gibson assembly_id is correct';
    is $test_gibson->chr_start, '141008069', 'gibson chr_start is correct';
    is $test_gibson->chr_end, '141008093', 'gibson chr_end is correct';
    is $test_gibson->chr_id, '3178', 'gibson chr_id is correct';
    is $test_gibson->chr_strand, '-1', 'gibson chr_strand is correct';
    is $test_gibson->design_id, '1002582', 'gibson design_id is correct';
    is $test_gibson->oligo_type_id, '3R', 'gibson oligo_type_id is correct';
    is $test_gibson->design_type_id, 'gibson', 'gibson design_type_id is correct';

    ok $gibson_design_rs = gibson_designs_for_region( model->schema, \%params ), 'Can re-run gibson design database query';
    ok my $test_gff_gibsons =  design_oligos_to_gff( $gibson_design_rs, \%params ), 'converted and returned gff3 format gibson design oligo data';
    is ref $test_gff_gibsons, 'ARRAY', 'result is an array reference';
    is scalar @$test_gff_gibsons, 10, 'Array has the correct number of elements';
    my @example_parent = grep { /ID=D_1002582/ } @$test_gff_gibsons;
    is scalar @example_parent, 1, 'Example contains just one example crispr pair';
    is $example_parent[0],
    "7\tLIMS2\tgibson\t141008069\t141011784\t.\t-\t.\tID=D_1002582;Name=D_1002582",
    'Parent row is in the correct format';
    my @example_child = grep { /ID=5F/ } @$test_gff_gibsons;
    is scalar @example_child, 1, 'Example contains just one example crispr pair';
    is $example_child[0],
    "7\tLIMS2\tCDS\t141011760\t141011784\t.\t-\t.\tID=5F;Parent=D_1002582;Name=5F;color=#68D310",
    'Child row is in the correct format';
}

## use critic

1;

__END__
