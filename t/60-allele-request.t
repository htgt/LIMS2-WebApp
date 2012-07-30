#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

#use LIMS2::Test;
use Test::Most;
use LIMS2::AlleleRequestFactory;

# XXX Naughty hack, we should really use LIMS2::Test
{
    require LIMS2::Model;

    my $model;
    
    sub model {
        return $model ||= LIMS2::Model->new( { user => 'tasks' } );
    }
}

ok my $arf = LIMS2::AlleleRequestFactory->new( model => model(), species => 'Mouse' ),
    'create allele request factory';

isa_ok $arf, 'LIMS2::AlleleRequestFactory';

throws_ok { $arf->allele_request() }
    qr/\Qallele_request() requires targeting_type\E/, 'allele_request requires targeting_type';

ok my $ar = $arf->allele_request(
    gene_id                         => 'MGI:1343161',
    targeting_type                  => 'double_targeted',
    first_allele_mutation_type      => 'ko first',
    first_allele_cassette_function  => 'ko first',
    second_allele_mutation_type     => 'ko first',
    second_allele_cassette_function => 'reporter only'
), 'constructor succeeds';

my $first_allele_designs;
lives_ok { $first_allele_designs = $ar->first_allele_designs } 'first_allele_designs succeeds';
cmp_bag [ map { $_->id } @{$first_allele_designs} ], [ 76 ], 'first_allele_designs returns expected result';

my $second_allele_designs;
lives_ok { $second_allele_designs = $ar->second_allele_designs } 'second_allele_designs succeeds';
cmp_bag [ map { $_->id } @{$second_allele_designs} ], [ 76 ], 'second_allele_designs returns expected result';

my $first_allele_design_wells;
lives_ok { $first_allele_design_wells = $ar->first_allele_design_wells } 'first_allele_design_wells succeeds';
cmp_bag [ map { $_->as_string } @{$first_allele_design_wells} ], [ '4_C04', '34_C04' ], 'first_allele_design_wells returns the expected result';

my $second_allele_design_wells;
lives_ok { $second_allele_design_wells = $ar->second_allele_design_wells } 'second_allele_design_wells succeeds';
cmp_bag [ map { $_->as_string } @{$second_allele_design_wells} ], [ '4_C04', '34_C04' ], 'second_allele_design_wells returns the expected result';

    




done_testing();
