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

{

    my %pspec = (
        name    => { validate => 'non_empty_string' },
        comment => { validate => 'non_empty_string', optional =>1, rename => 'comment_text' },
        user    => { validate => 'existing_user', optional =>1, post_filter => 'user_id_for' },
    );

    my $validated_params;
    lives_ok {
        $validated_params = model->check_params( { name => 'test' }, \%pspec )
    } 'validate test values';

    is_deeply $validated_params, { name => 'test' }, '.. validated params hash only has name';

    my $validated_params2;
    lives_ok {
        $validated_params2 = model->check_params(
            { name => 'test', user => 'test_user@example.org', comment => 'comment' }, \%pspec );
    }
    'validate test values';

    is_deeply $validated_params2, { name => 'test', comment_text => 'comment', user => 1 },
        '.. validated params hash has all 3 values';

}




{
    my %constraint_test_hash = (
        integer => [
            { name => 'integer too big', pass  => 0, value => 999999999999999999 },
            { name => 'integer too small', pass => 0, value => -99999999999999999 },
            { pass => 1, value => 9999, },
        ],
        alphanumeric_string => [
            { name => 'non alpha numeric', pass => 0, value => 'asdf%' },
            { name => 'non alpha numeric', pass => 0, value => '9998.9'},
            { pass => 1, value => 'sdf_sdfs87' },
        ],
        mgi_accession_id => [
            { pass => 0, value => 'MGD:skdjfhk' },
            { pass => 1, value => 'MGI:98798' },
        ],
        ensembl_gene_id => [
            { pass => 0, value => 'EDS345345' },
            { pass => 1, value => 'ENSMUSG00000018666' },
        ],
        phase => [
            { pass => 0, value => -2 },
            { pass => 1, value => 2 },
        ],
        validated_by_annotation => [
            { pass => 0, value => 'possibly' },
            { pass => 1, value => 'yes' },
        ],
        cre_bac_recom_bac_library => [
            { pass => 0, value => 'notblack6' },
            { pass => 1, value => 'black6' },
        ],
        cre_bac_recom_bac_name => [
            { pass => 0, value => 'RP25' },
            { pass => 1, value => 'RP23' },
        ],
        cre_bac_recom_cassette => [
            { pass => 0, value => 'pL1L2_BactP' },
            { pass => 1, value => 'pGTK_En2_eGFPo_T2A_CreERT_Kan' },
        ],
        cre_bac_recom_backbone => [
            { pass => 0, value => 'R3R4_pBR_amp' },
            { pass => 1, value => 'pBACe3.6 (RP23) with HPRT3-9 without PUC Linker' },
        ],
        existing_design_comment_category => [
            { pass => 0, value => 'foo bar' },
            { pass => 1, value => 'Recovery design' },
        ],
        existing_design_oligo_type => [
            { pass => 0, value => 'F5' },
            { pass => 1, value => 'U5' },
        ],
        existing_recombineering_result_type => [
            { pass => 0, value => 'pcr_z' },
            { pass => 1, value => 'pcr_u' },
        ],
        recombineering_result=> [
            { pass => 0, value => 'foo' },
            { pass => 1, value => 'pass' },
        ],
        dna_quality=> [
            { pass => 0, value => 'Z' },
            { pass => 1, value => 'L' },
        ],
        existing_genotyping_primer_type => [
            { pass => 0, value => 'ZR4' },
            { pass => 1, value => 'GF1' },
        ],
        ensembl_transcript_id => [
            { pass => 0, value => 'ENSMUSG12349' },
            { pass => 1, value => 'ENSMUST23346' },
        ],
        file_handle => [
            { pass => 0, value => 'file' },
            { pass => 1, value => IO::File->new_tmpfile },
        ],
        absolute_url => [
            { pass => 0, value => undef },
            { pass => 0, value => '' },
            { pass => 0, value => 'http://www.sanger.ac.uk' },
            { pass => 1, value => 'http://www.sanger.ac.uk/htgt/welcome' },
        ],
    );

    for my $validate_test ( keys %constraint_test_hash ) {
        my %pspec = ( value => { validate => $validate_test } );

        for my $test ( @{ $constraint_test_hash{$validate_test} } ) {
            if ( $test->{pass} ){
                lives_ok {
                    model->check_params( { value => $test->{value} }, \%pspec )
                } "validate passes for $validate_test with value $test->{value}";
            }
            else {
                my $test_name = exists $test->{name} ? $test->{name} : "non $validate_test";
                throws_ok {
                    model->check_params( { value => $test->{value} }, \%pspec );
                } 'LIMS2::Exception::Validation', $test_name;
            }
        }
    }

}

{
    use JSON;
    my %pspec = ( value => { validate => 'json' } );

    my $data = { test => 'foo' };

    my $json = JSON->new;
    my $json_data = $json->encode( $data );

    throws_ok {
        model->check_params( { value => $data }, \%pspec );
    } 'LIMS2::Exception::Validation', 'non json data fails test' ;

    lives_ok {
        model->check_params( { value => $json_data }, \%pspec )
    } "validate passes for json";

}


done_testing;
