#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

my $model = model();

note "Testing create_bac_clone";

can_ok $model, 'create_bac_clone';

my %bac1_data = (
    bac_library => 'black6',
    bac_name    => 'CT7-148D8'
);

ok my $bac1 = $model->create_bac_clone( \%bac1_data ),
    'create bac with no locus';

$bac1_data{id} = $bac1->id;

is_deeply $bac1->as_hash, \%bac1_data, 'as_hash() returns expected data structure';

my %bac2_data = (
    bac_library =>  'black6',
    bac_name    =>  'CT7-156D9',
    loci        => [
        {
            assembly  => 'NCBIM37',
            chr_end   => 194680061,
            chr_start => 194454015,
            chr_name  => '1'
        }
    ]        
);

ok my $bac2 = $model->create_bac_clone( \%bac2_data ),
    'create bac with NCBIM37 locus';

$bac2_data{id} = $bac2->id;

is_deeply $bac2->as_hash, \%bac2_data, 'as_hash() returns expected data structure';

note "Testing delete_bac_clone";

can_ok $model, 'delete_bac_clone';

ok $model->delete_bac_clone( { bac_library => $bac1->bac_library_id,
                               bac_name    => $bac1->name } ), 'delete bac with no locus';

ok $model->delete_bac_clone( { bac_library => $bac2->bac_library_id,
                               bac_name    => $bac2->name } ), 'delete bac with NCBIM37 locus';

done_testing;

