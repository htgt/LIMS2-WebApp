package LIMS2::t::Model::Util::Trivial;
use strict;
use warnings;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::Trivial;
use LIMS2::t::Model::Util::Trivial::ExperimentManager;
use LIMS2::Test;
use LIMS2::Test model => { classname => __PACKAGE__ };

sub new_crispr : Test(9) {
    my $manager = LIMS2::t::Model::Util::Trivial::ExperimentManager->new( model,
        'HGNC:18039' );
    $manager->expect(
        1999 => 'KDM5B_1A1',
        2052 => 'KDM5B_2A1',
        2053 => 'KDM5B_3A1'
    );
    $manager->test;

    $manager->add( 'KDM5B_4A1', { crispr_id => 228036, design_id => 1016484 } );
    $manager->test;
}

sub new_designs : Test(6) {
    my $manager = LIMS2::t::Model::Util::Trivial::ExperimentManager->new( model,
        'HGNC:11204' );
    $manager->expect( 2100 => 'SOX9_1A1' );
    $manager->test;

    $manager->add( 'SOX9_1B1', { crispr_id => 227838, design_id => 1016560 } );
    $manager->add( 'SOX9_1C1', { crispr_id => 227838, design_id => 1016557 } );
    $manager->test;
}

sub new_experiment : Test(9) {
    my $manager = LIMS2::t::Model::Util::Trivial::ExperimentManager->new( model,
        'HGNC:1338' );
    $manager->expect(
        632  => 'C5AR1_1A1',
        2062 => 'C5AR1_2A1',
        2063 => 'C5AR1_3A1'
    );
    $manager->test;

    $manager->add( 'C5AR1_2A2',
        { crispr_id => 226732, crispr_group_id => 603, design_id => 1016416 } );
    $manager->test;
}

sub assigned_name : Test(13) {
    my $manager = LIMS2::t::Model::Util::Trivial::ExperimentManager->new( model,
        'HGNC:1884' );
    $manager->expect(
        2069 => 'CFTR',
        2070 => 'CFTR_2',
    );
    $manager->test;
    # a new experiment, using the same CRISPR as the later (by experiment creation time) of the assigned ones
    # it should ignore that and start indexing after the allocated offset
    $manager->add( 'CFTR_3A1', { crispr_id => 228048, design_id => 1016423 } );
    # a new experiment, using the same CRISPR as the earlier (by experiment creation time) of the assigned ones
    # goes after that other one
    $manager->add( 'CFTR_4A1', { crispr_id => 228050, design_id => 1016424 } );
    # create a new experiment with a new CRISPR, continue incrementing the CRISPR index
    $manager->add( 'CFTR_5A1', { crispr_id => 228049, design_id => 1016423 } );
    # try incrementing designs and experiments too
    $manager->add( 'CFTR_3B1', { crispr_id => 228048, design_id => 1016425 } );
    $manager->add( 'CFTR_5B1', { crispr_id => 228049, design_id => 1016424 } );
    $manager->add( 'CFTR_5C1', { crispr_id => 228049, design_id => 1016425 } );
    $manager->add( 'CFTR_5B2', { crispr_id => 228049, design_id => 1016424, crispr_group_id => 10001 } );
    $manager->test;
}

sub num2alpha : Test(9) {
    ok my $converter = \&LIMS2::Model::Util::Trivial::numeric_to_alpha;
    is( $converter->(1),   'A' );
    is( $converter->(2),   'B' );
    is( $converter->(5),   'E' );
    is( $converter->(26),  'Z' );
    is( $converter->(27),  'AA' );
    is( $converter->(28),  'AB' );
    is( $converter->(56),  'BD' );
    is( $converter->(705), 'AAC' );
}

1;
