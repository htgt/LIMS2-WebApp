#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use Const::Fast;
use LIMS2::AlleleRequestFactory;

=pod

Negative tests as well - i.e. when nothing meets the allele spec

* final_vector_wells but no electroporation_wells
* Gene has SEP but first (or second) allele not satisfied

** Make sure all the subsequent methods work and return something sensible

=cut

const my @TEST_DATA => (
    # Expect everything up to SEP
    {
        allele_request => {
            gene_id                         => 'MGI:1914632',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only'
        },
        first_allele_designs         => [ 34188 ],
        first_allele_design_wells    => [ '56_G04' ],
        second_allele_designs        => [ 34188 ],
        second_allele_design_wells   => [ '56_G04' ],
        first_allele_vector_wells    => [ 'MOHFAS0001_A_H02' ],
        second_allele_vector_wells   => [ 'MOHSAS0001_A_H02' ],
        first_electroporation_wells  => [ 'FEP0006_A01' ],
        second_electroporation_wells => [ 'SEP0006_C01' ]
    },
    # The first allele has a promoterless cassette - also expect everything up to SEP
    {
        allele_request => {
            gene_id                         => 'MGI:1914632',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first_promoterless',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only'
        },
        first_allele_designs         => [ 34188 ],
        first_allele_design_wells    => [ '56_G04' ],
        second_allele_designs        => [ 34188 ],
        second_allele_design_wells   => [ '56_G04' ],
        first_allele_vector_wells    => [ 'MOHFAS0001_A_H02' ],
        second_allele_vector_wells   => [ 'MOHSAS0001_A_H02' ],
        first_electroporation_wells  => [ 'FEP0006_A01' ],
        second_electroporation_wells => [ 'SEP0006_C01' ]
    },
    # There's no first allele with promoter cassette
    {
        allele_request => {
            gene_id                         => 'MGI:1914632',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first_promoter',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only'
        },
        first_allele_designs         => [ 34188 ],
        first_allele_design_wells    => [ '56_G04' ],
        second_allele_designs        => [ 34188 ],
        second_allele_design_wells   => [ '56_G04' ],
        first_allele_vector_wells    => [],
        second_allele_vector_wells   => [ 'MOHSAS0001_A_H02' ],
        first_electroporation_wells  => [],
        second_electroporation_wells => []
    },
    # This gene has no designs
    {
        allele_request => {
            gene_id                         => 'MGI:1914631',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only'
        },
        first_allele_designs         => [],
        first_allele_design_wells    => [],
        second_allele_designs        => [],
        second_allele_design_wells   => [],
        first_allele_vector_wells    => [],
        second_allele_vector_wells   => [],
        first_electroporation_wells  => [],
        second_electroporation_wells => []
    },
    # The second allele has a promoterless cassette - expect everything up to SEP
    {
        allele_request => {
            gene_id                         => 'MGI:1914632',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only_promoterless'
        },
        first_allele_designs         => [ 34188 ],
        first_allele_design_wells    => [ '56_G04' ],
        second_allele_designs        => [ 34188 ],
        second_allele_design_wells   => [ '56_G04' ],
        first_allele_vector_wells    => [ 'MOHFAS0001_A_H02' ],
        second_allele_vector_wells   => [ 'MOHSAS0001_A_H02' ],
        first_electroporation_wells  => [ 'FEP0006_A01' ],
        second_electroporation_wells => [ 'SEP0006_C01' ]
    },
    # There's no second allele with a promoter cassette
    {
        allele_request => {
            gene_id                         => 'MGI:1914632',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only_promoter'
        },
        first_allele_designs         => [ 34188 ],
        first_allele_design_wells    => [ '56_G04' ],
        second_allele_designs        => [ 34188 ],
        second_allele_design_wells   => [ '56_G04' ],
        first_allele_vector_wells    => [ 'MOHFAS0001_A_H02' ],
        second_allele_vector_wells   => [],
        first_electroporation_wells  => [ 'FEP0006_A01' ],
        second_electroporation_wells => []
    },
    # No design instances
    {
        allele_request => {
            gene_id                         => 'MGI:2663588',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only_promoter'
        },
        first_allele_designs         => [ 39175 ],
        first_allele_design_wells    => [],
        second_allele_designs        => [ 39175 ],
        second_allele_design_wells   => [],
        first_allele_vector_wells    => [],
        second_allele_vector_wells   => [],
        first_electroporation_wells  => [],
        second_electroporation_wells => []
    },
    # Design instances but no final vector wells
    {
        allele_request => {
            gene_id                         => 'MGI:2444518',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only_promoter'
        },
        first_allele_designs         => [ 81136 ],
        first_allele_design_wells    => [ '98_A01' ],
        second_allele_designs        => [ 81136 ],
        second_allele_design_wells   => [ '98_A01' ],
        first_allele_vector_wells    => [],
        second_allele_vector_wells   => [],
        first_electroporation_wells  => [],
        second_electroporation_wells => []
    },
    # Final vector wells but no electroporation wells
    {
        allele_request => {
            gene_id                         => 'MGI:94912',
            targeting_type                  => 'double_targeted',
            first_allele_mutation_type      => 'ko_first',
            first_allele_cassette_function  => 'ko_first',
            second_allele_mutation_type     => 'ko_first',
            second_allele_cassette_function => 'reporter_only_promoter'
        },
        first_allele_designs         => [ 116636 ],
        first_allele_design_wells    => [ '148_F02' ],
        second_allele_designs        => [ 116636 ],
        second_allele_design_wells   => [ '148_F02' ],
        first_allele_vector_wells    => [ 'MOHFAQ0001_A_1_D04' ],
        second_allele_vector_wells   => [ 'MOHSAQ0001_A_1_D04' ],
        first_electroporation_wells  => [],
        second_electroporation_wells => []
    },
);

ok my $factory = LIMS2::AlleleRequestFactory->new( model => model(), species => 'Mouse' ),
    'create allele request factory';

isa_ok $factory, 'LIMS2::AlleleRequestFactory';

throws_ok { $factory->allele_request() }
    qr/\Qallele_request() requires targeting_type\E/, 'allele_request requires targeting_type';

throws_ok { $factory->allele_request( targeting_type => 'no_such_targeting_type' ) }
    qr/\QAllele request targeting type 'no_such_targeting_type' not recognized\E/, 'unrecognised targeting type';

my $invalid_cassette_function_data = {
    gene_id                         => 'MGI:1914632',
    targeting_type                  => 'double_targeted',
    first_allele_mutation_type      => 'ko_first',
    first_allele_cassette_function  => 'imaginary_cassette_function',
    second_allele_mutation_type     => 'ko_first',
    second_allele_cassette_function => 'reporter_only'
};
my $icfar = $factory->allele_request( $invalid_cassette_function_data );
throws_ok { $icfar->first_allele_vector_wells } qr/\QUnrecognized cassette function 'imaginary_cassette_function'\E/, 'unrecognised cassette function';

throws_ok { $icfar->design_types_for( 'imaginary_mutation_type' ) } qr/\QUnrecognized mutation type: imaginary_mutation_type\E/, 'unrecognised mutation type';

for my $test_data ( @TEST_DATA ) {    
    run_allele_request_test( $factory, $test_data );
}

done_testing;

sub run_allele_request_test {
    my ( $factory, $test_data ) = @_;

    ok my $ar = $factory->allele_request( $test_data->{allele_request} ),
        'allele_request succeeds';

    for my $method (
        qw( first_allele_designs second_allele_designs
            first_allele_design_wells second_allele_design_wells
            first_allele_vector_wells second_allele_vector_wells
            first_electroporation_wells second_electroporation_wells
      ) ) {
        check_lives_and_cmp_bag( $ar, $test_data, $method );
    }
}

sub check_lives_and_cmp_bag {
    my ( $ar, $test_data, $method ) = @_;

    return unless exists $test_data->{$method};

    my $result;
    lives_ok { $result = $ar->$method() } "$method succeeds";
    cmp_bag [ map { $_->as_string } @{$result} ], $test_data->{$method},
        "$method returns the expected result";
}
