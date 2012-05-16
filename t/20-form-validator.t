#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Data::FormValidator;
use LIMS2::Model::Test;
use LIMS2::Model::DBConnect;

can_ok model(), 'check_params';

ok my $pspec = model->pspec_find_or_create_qc_seq_read,
    'parameter specification for find_or_create_qc_seq_read';

ok my $dfv_profile = model->form_validator->dfv_profile( $pspec ),
    'create Data::FormValidater profile from parameter spec';

{
    my $res = Data::FormValidator->check(
        {
            id                    => 'VTP0000_A01.Plkr',
            qc_seq_project_id     => 'FOO11111',
            well_name             => 'A01',
            plate_name            => 'VTP0000',
            primer_name           => 'r',
            description           => 'foo',
            seq                   => 'ATCG',
            length                => 10,
        }, $dfv_profile
    );

    isa_ok $res, 'Data::FormValidator::Results';

    ok $res->success, 'result is success';
}

{
    my $res = Data::FormValidator->check(
        {
            id                    => '0',
            qc_seq_project_id     => 'FOO11111',
            description           => 'foo',
            seq                   => 'ATCG',
            well_name             => 'A01',
            plate_name            => 'FOO11111',
            primer_name           => 'LR'
        }, $dfv_profile
    );

    isa_ok $res, 'Data::FormValidator::Results';

    ok ! $res->success, 'result is not success';

    ok $res->has_invalid, 'result has_invalid';

    is_deeply [ $res->invalid ], [ 'id' ], 'id is invalid';

    ok $res->has_missing, 'result has missing';

    is_deeply [ $res->missing ], [ 'length' ], 'length is missing';
}

{
    lives_ok {
        model->check_params(
            { cassette => 'pR6K_R1R2_ZP' },
            { cassette => { validate => 'existing_intermediate_cassette' } }
        )
    } 'check existing_intermediate_cassette';
}

{
    my %pspec = ( foo => { validate => 'comma_separated_list' } );

    lives_ok {
        model->check_params( { foo => 'abc' }, \%pspec )
    } 'comma_separated_list validates single-element list';

    lives_ok {
        model->check_params( { foo => 'abc,2,def,34' } )
    } 'comma_separeted_list validates multi-element list';
}

done_testing;

