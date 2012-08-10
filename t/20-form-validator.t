#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Data::FormValidator;
use LIMS2::Test;

can_ok model(), 'check_params';

ok my $pspec = model->pspec_find_or_create_qc_seq_read,
    'parameter specification for find_or_create_qc_seq_read';

ok my $dfv_profile = model->form_validator->dfv_profile( $pspec ),
    'create Data::FormValidater profile from parameter spec';

{
    my $res = Data::FormValidator->check(
        {
            id                    => 'VTP0000_A01.Plkr',
            species               => 'Mouse',
            qc_run_id             => '3C41F49A-B6D6-11E1-8038-C8C8F7D1DA10',
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
            species               => 'Mouse',
            qc_run_id             => '3C41F49A-B6D6-11E1-8038-C8C8F7D1DA10',
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
    my %pspec = ( foo => { validate => 'comma_separated_list', optional => 1 } );

    lives_ok {
        model->check_params( { foo => 'abc' }, \%pspec )
    } 'comma_separated_list validates single-element list';

    lives_ok {
        model->check_params( { foo => 'abc,2,def,34' }, \%pspec )
    } 'comma_separeted_list validates multi-element list';

    lives_ok {
        model->check_params( { foo => '' }, \%pspec )
    } 'comma_separeted_list validates empty list';
}

{
    my %pspec = ( url => { validate => 'absolute_url' } );

    lives_ok {
        model->check_params( { url => 'http://example.org/foo/bar' }, \%pspec )
    } 'validate absolute_url';

    for my $url ( qw( /foo/bar http:/foo/bar http://foo ) ) {
        throws_ok {
            model->check_params( { url => $url }, \%pspec );
        } 'LIMS2::Exception::Validation', "$url is not an absolute URL";
    }
}

{
    my %pspec = ( cassette => { validate => 'existing_intermediate_cassette' } );

    lives_ok {
        model->check_params( { cassette => 'pR6K_R1R2_ZP' }, \%pspec )
    } 'validate cassettte';

    throws_ok {
        model->check_params( { cassette => 'pR6K_R1R2_ZP', foo => 'foo' }, \%pspec );
    } 'LIMS2::Exception::Validation', "Throw error if unknown value passed in";

    lives_ok {
        model->check_params( { cassette => 'pR6K_R1R2_ZP', foo => 'foo' }, \%pspec, ignore_unknown => 1 );
    } 'ignore extra param values when ignore_unknown flag set';

}

done_testing;
