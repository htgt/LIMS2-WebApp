#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use Const::Fast;
use LIMS2::AlleleRequestFactory;

const my @TEST_DATA => (
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
    }
);

ok my $factory = LIMS2::AlleleRequestFactory->new( model => model(), species => 'Mouse' ),
    'create allele request factory';

isa_ok $factory, 'LIMS2::AlleleRequestFactory';

throws_ok { $factory->allele_request() }
    qr/\Qallele_request() requires targeting_type\E/, 'allele_request requires targeting_type';

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
