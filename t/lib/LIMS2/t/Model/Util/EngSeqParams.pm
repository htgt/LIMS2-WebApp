package LIMS2::t::Model::Util::EngSeqParams;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::EngSeqParams qw(
    fetch_well_eng_seq_params
    generate_well_eng_seq_params
    generate_crispr_eng_seq_params
    generate_custom_eng_seq_params
);

use LIMS2::Test ( 'test_data', model => { classname => __PACKAGE__ } );

use strict;

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

## no critic

=head1 NAME

LIMS2/t/Model/Util/EngSeqParams.pm - test class for LIMS2::Model::Util::EngSeqParams

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

sub fetch_well_eng_seq_params_test : Tests(36) {

    ok my $design_well = model->retrieve_well( { well_name => 'F02', plate_name => '148' } ),
        'can grab design well';

    # DESIGN templates can now have no cassette for PREINT plate creation

    # throws_ok {
    #     fetch_well_eng_seq_params(
    #         $design_well,
    #         {   stage                 => 'allele',
    #             design_type           => 'conditional',
    #             design_cassette_first => 1,
    #             recombinase           => [],
    #         }
    #     );
    # }
    # qr/No cassette found for well/, 'throws error when it can not work out cassette for well ';

    throws_ok {
        fetch_well_eng_seq_params(
            $design_well,
            {   stage                 => 'vector',
                design_type           => 'conditional',
                design_cassette_first => 1,
                recombinase           => [],
                cassette              => 'foo',
            }
        );
    }
    qr/No backbone found for well/, 'throws error when it can not work out backbone for well ';

    ok my $well = model->retrieve_well( { well_name => 'H03', plate_name => 'ETPCS0004_A' } ),
        'grab test well';

    ok my ( $method, $params ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'allele',
            design_type           => 'conditional',
            design_cassette_first => 1,
            recombinase           => [],
        }
        ),
        'call fetch_well_eng_seq_params for standard conditional allele';

    is $method, 'conditional_allele_seq', '.. method is correct';
    is_deeply $params->{u_insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have right cassette in u_insertion slot';
    is_deeply $params->{d_insertion}, { name => 'LoxP' }, '.. have LoxP in d_insertion slot';
    is_deeply $params->{recombinase}, [], '.. no recombinases';

    ok my ( $method2, $params2 ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'allele',
            design_type           => 'conditional',
            design_cassette_first => 0,
            recombinase           => ['Cre'],
        }
        ),
        'call fetch_well_eng_seq_params for LoxP first conditional allele';

    is $method2, 'conditional_allele_seq', '.. method is correct';
    is_deeply $params2->{u_insertion}, { name => 'LoxP' }, '.. have LoxP in u_insertion slot';
    is_deeply $params2->{d_insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in d_insertion slot';
    is_deeply $params2->{recombinase}, ['cre'], '.. have one recombinase';

    ok my ( $method3, $params3 ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'vector',
            design_type           => 'conditional',
            design_cassette_first => 1,
            recombinase           => [],
            cassette              => 'foo'
        }
        ),
        'call fetch_well_eng_seq_params for standard conditional vector';

    is $method3, 'conditional_vector_seq', '.. method is correct';
    is_deeply $params3->{u_insertion}, { name => 'foo' },
        '.. have specified cassette in u_insertion slot';
    is_deeply $params3->{d_insertion}, { name => 'LoxP' }, '.. have LoxP in d_insertion slot';
    is_deeply $params3->{backbone}, { name => 'R3R4_pBR_amp' }, '.. have backbone information';

    ok my ( $method4, $params4 ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'vector',
            design_type           => 'conditional',
            design_cassette_first => 0,
            recombinase           => [],
            cassette              => 'foo',
            backbone              => 'bar',
        }
        ),
        'call fetch_well_eng_seq_params for standard conditional vector';

    is $method4, 'conditional_vector_seq', '.. method is correct';
    is_deeply $params4->{u_insertion}, { name => 'LoxP' }, '.. have LoxP in u_insertion slot';
    is_deeply $params4->{d_insertion}, { name => 'foo' },
        '.. have specified cassette in d_insertion slot';
    is_deeply $params4->{backbone}, { name => 'bar' }, '.. have backbone information';

    ok my ( $method5, $params5 ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'allele',
            design_type           => 'deletion',
            design_cassette_first => 1,
            recombinase           => [],
        }
        ),
        'call fetch_well_eng_seq_params for deletion allele';

    is $method5, 'deletion_allele_seq', '.. method is correct';
    is_deeply $params5->{insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in insertion slot';

    ok my ( $method6, $params6 ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'allele',
            design_type           => 'insertion',
            design_cassette_first => 1,
            recombinase           => [],
        }
        ),
        'call fetch_well_eng_seq_params for insertion allele';

    is $method6, 'insertion_allele_seq', '.. method is correct';
    is_deeply $params6->{insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in insertion slot';

    ok my ( $method7, $params7 ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'vector',
            design_type           => 'deletion',
            design_cassette_first => 1,
            recombinase           => [],
        }
        ),
        'call fetch_well_eng_seq_params for deletion allele';

    is $method7, 'deletion_vector_seq', '.. method is correct';
    is_deeply $params7->{insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in insertion slot';

    ok my ( $method8, $params8 ) = fetch_well_eng_seq_params(
        $well,
        {   stage                 => 'vector',
            design_type           => 'insertion',
            design_cassette_first => 1,
            recombinase           => [],
        }
        ),
        'call fetch_well_eng_seq_params for insertion allele';

    is $method8, 'insertion_vector_seq', '.. method is correct';
    is_deeply $params8->{insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in insertion slot';
}

sub fetch_eng_seq_params_test : Tests(14) {

    my $fetch_eng_seq_params  = \&LIMS2::Model::Util::EngSeqParams::fetch_eng_seq_params;
    throws_ok {
        $fetch_eng_seq_params->(
            {   stage                 => 'allele',
                design_type           => 'foo',
                design_cassette_first => 1,
                recombinase           => [],
                cassette              => 'moo'
            }
        );
    }
    qr/Don't know how to generate allele seq/, 'throws error when unknown design type used';

    throws_ok {
        $fetch_eng_seq_params->(
            {   stage                 => 'vector',
                design_type           => 'foo',
                design_cassette_first => 1,
                recombinase           => [],
                cassette              => 'moo'
            }
        );
    }
    qr/Don't know how to generate vector seq/, 'throws error when unknown design type used';

    ok my $well = model->retrieve_well( { well_name => 'H03', plate_name => 'ETPCS0004_A' } ),
        'grab test well';

    ok my ( $method6, $params6 ) = $fetch_eng_seq_params->(
        {   stage                 => 'allele',
            design_type           => 'insertion',
            design_cassette_first => 1,
            recombinase           => [],
            cassette              => 'pR6K_R1R2_ZP',
        }
        ),
        'call fetch_eng_seq_params for insertion allele';

    is $method6, 'insertion_allele_seq', '.. method is correct';
    is_deeply $params6->{insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in insertion slot';

    ok my ( $method7, $params7 ) = $fetch_eng_seq_params->(
        {   stage                 => 'vector',
            design_type           => 'deletion',
            design_cassette_first => 1,
            recombinase           => [],
            cassette              => 'pR6K_R1R2_ZP',
            backbone              => 'foo',
        }
        ),
        'call fetch_eng_seq_params for deletion allele';

    is $method7, 'deletion_vector_seq', '.. method is correct';
    is_deeply $params7->{insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in insertion slot';
    is_deeply $params7->{backbone}, { name => 'foo' },
        '.. have cassette in insertion slot';

    ok my ( $method8, $params8 ) = $fetch_eng_seq_params->(
        {   stage                 => 'vector',
            design_type           => 'insertion',
            design_cassette_first => 1,
            recombinase           => [],
            cassette              => 'pR6K_R1R2_ZP',
            backbone              => 'foo',
        }
        ),
        'call fetch_eng_seq_params for insertion allele';

    is $method8, 'insertion_vector_seq', '.. method is correct';
    is_deeply $params8->{insertion}, { name => 'pR6K_R1R2_ZP' },
        '.. have cassette in insertion slot';
    is_deeply $params7->{backbone}, { name => 'foo' },
        '.. have cassette in insertion slot';

}

sub generate_well_eng_seq_params_test : Test(11) {
    throws_ok {
        generate_well_eng_seq_params( model, { well_id => 850 } );
    }
    qr/No backbone found for well/;

    throws_ok {
        generate_well_eng_seq_params( model, { well_id => 3032 } );
    }
    qr/well that has a nonsense type design/;

    ok my ( $method, $well_id, $params )
        = generate_well_eng_seq_params( model, { well_id => 1522 } ),
        'generate_well_eng_seq_params for well 1522 should succeed';
    is $well_id, 1522, 'correct source well id returned';
    is $method, 'conditional_allele_seq', 'engseq method correct for well 1522';
    is_deeply( $params, test_data('well_1522.yaml'), 'engseq params as expected for well 1522' );

    my %user_params = (
        cassette    => 'L1L2_GT2_LacZ_BSD',
        backbone    => 'R3R4_pBR_amp',
        recombinase => ['Cre'],
        stage       => 'vector',
    );
    ok my ( $method2, $well_id2, $params2 )
        = generate_well_eng_seq_params( model, { well_id => 850, %user_params } ),
        'generate well_eng_seq_params for well 850 with user specified details should succeed';
    is_deeply(
        $params2,
        test_data("well_850_user_params.yaml"),
        'engseq params as expected for well 850 with user specified params'
    );

    is $method2, 'conditional_vector_seq', 'engseq method correct for well 850';

    ok my ( $method3, $well_id3, $params3 )
        = generate_well_eng_seq_params( model, { well_id => 848, %user_params } ),
        'generate_well_eng_seq_params for well 848 should succeed';
    is_deeply( $params3, test_data('well_848.yaml'), 'engseq params as expected for well 848' );

}

sub generate_crispr_eng_seq_params_test : Test(8) {

    ok my $crispr = model->retrieve_crispr( { id => 886 } ), 'can grab a crispr';
    ok my $well = model->retrieve_well( { plate_name => 'CRISPR_1', well_name => 'A01' } ),
        'can grab crispr well';

    ok my ( $method, $well_id, $eng_seq_params )
        = generate_crispr_eng_seq_params( $well, $crispr, { backbone => 'blah' } ),
        'can call generate_crispr_eng_seq_params';

    is $method, 'crispr_vector_seq', 'correct eng seq method';
    is $well_id, $well->id, 'correct well_id';
    is_deeply $eng_seq_params,
        {
        crispr_seq => 'GGGGATATCGGCCCCAAGTT',
        backbone   => { name => 'blah' },
        display_id => 'blah#886',
        crispr_id  => $crispr->id,
        species    => 'mouse',
        },
        'eng seq params are correct';

    throws_ok {
        generate_crispr_eng_seq_params( $well, $crispr, { backbone => 'blah', cassette => 'foo' } );
    }
    qr/Can not specify a cassette for crispr well/, 'throws error if you pass in a cassette';

    throws_ok {
        generate_crispr_eng_seq_params( $well, $crispr, {} );
    }
    qr/No backbone found for well/,
        'throws error if you do not specify a backbone override and the well has no backbone';
}

sub generate_custom_eng_seq_params_test : Tests(8) {
    # Using test data from wells which use the designs below to test against
    # Manually add the correct cassette and backbone, so the parameters should
    # match up exactly

    ok my ( $method, $params ) = generate_custom_eng_seq_params( model,
        {
            design_id => 42815,
            cassette => 'L1L2_gt0_Del_LacZ',
        } ),
        'generate_custom_eng_seq_params for design 42815 should succeed';
    is $method, 'conditional_allele_seq', 'engseq method correct for design 42815';
    is_deeply( $params, test_data('well_1522.yaml'), 'engseq params as expected for design 42815' );

    ok my ( $method2, $params2 ) = generate_custom_eng_seq_params( model,
        {
            design_id => 84231,
            cassette  => 'L1L2_GT2_LacZ_BSD',
            backbone  => 'R3R4_pBR_amp',
            recombinases => [ 'Cre' ],
        } ),
        'generate_custom_eng_seq_params for design 84231 with user specified details should succeed';
    is_deeply(
        $params2,
        test_data("well_850_user_params.yaml"),
        'engseq params as expected for design 84231 with user specified params'
    );
    is $method2, 'conditional_vector_seq', 'engseq method correct for design 84231';

    ok my ( $method3, $params3 ) = generate_custom_eng_seq_params( model, {
            design_id => 170606,
            cassette  => 'L1L2_GT2_LacZ_BSD',
            backbone  => 'R3R4_pBR_amp',
            recombinases => [ 'Cre' ],
        } ),
        'generate_custom_eng_seq_params for design 170606 should succeed';
    is_deeply( $params3, test_data('well_848.yaml'), 'engseq params as expected for design 170606' );

}

## use critic

1;

__END__
