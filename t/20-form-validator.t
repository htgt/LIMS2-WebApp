#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Data::FormValidator;
use LIMS2::Model;
use LIMS2::Model::DBConnect;

ok my $schema = LIMS2::Model::DBConnect->connect( $ENV{LIMS2_DB}, 'tests' ),
    'connect to LIMS2_DB';

ok my $model = LIMS2::Model->new( schema => $schema ),
    'created model';

can_ok $model, 'check_params';

ok my $pspec = $model->pspec_create_bac_clone,
    'parameter specification for create_bac_clone';

ok my $dfv_profile = $model->form_validator->dfv_profile( $pspec ),
    'create Data::FormValidater profile from parameter spec';

{   
    my $res = Data::FormValidator->check(
        {
            library => 'black6',
            name    => 'foo'
        }, $dfv_profile
    );    

    isa_ok $res, 'Data::FormValidator::Results';

    ok $res->success, 'result is success';
}

{
    my $res = Data::FormValidator->check(
        {
            library => '128'
        }, $dfv_profile
    );

    isa_ok $res, 'Data::FormValidator::Results';

    ok ! $res->success, 'result is not success';

    ok $res->has_invalid, 'result has_invalid';

    is_deeply [ $res->invalid ], [ 'library' ], 'library is invalid';

    ok $res->has_missing, 'result has missing';

    is_deeply [ $res->missing ], [ 'name' ], 'name is missing';
}

{
    lives_ok {
        $model->check_params(
            { cassette => 'pR6K_R1R2_ZP' },
            { cassette => { validate => 'existing_intermediate_cassette' } }
        )
    } 'check existing_intermediate_cassette';
}

{
    my %pspec = ( foo => { validate => 'comma_separated_list' } );    
    
    lives_ok {
        $model->check_params( { foo => 'abc' }, \%pspec )
    } 'comma_separated_list validates single-element list';

    lives_ok {
        $model->check_params( { foo => 'abc,2,def,34' } )
    } 'comma_separeted_list validates multi-element list';
}

done_testing;

