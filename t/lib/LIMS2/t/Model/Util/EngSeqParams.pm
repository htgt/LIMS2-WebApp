package LIMS2::t::Model::Util::EngSeqParams;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::EngSeqParams qw( fetch_well_eng_seq_params );

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/EngSeqParams.pm - test class for LIMS2::Model::Util::EngSeqParams

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
};

=head2 before

Code to run before every test

=cut

sub before : Test(setup)
{
    #diag("running before test");
};

=head2 after

Code to run after every test

=cut

sub after  : Test(teardown)
{
    #diag("running after test");
};


=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup)
{
    #diag("running before all tests");
};

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown  : Test(shutdown)
{
    #diag("running after all tests");
};

=head2 all_tests

Code to execute all tests

=cut

sub all_tests  : Test(1)
{
    local $TODO = 'Complete testing of LIMS2::Model::Util::EngSeqParams not implemented yet';
    ok(1, "Test of LIMS2::Model::Util::EngSeqParams");
}

#NOTE I modified the fetch_well_eng_seq_params subroutine so I decided to test it
#     fully, I have not tested the other subroutines
#     sp12 Wed 04 Sep 2013 07:37:49 BST
sub fetch_well_eng_seq_params_test : Test(36) {

    ok my $design_well = model->retrieve_well( { well_name => 'F02', plate_name => '148' } )
        ,'can grab design well';

     throws_ok {
         fetch_well_eng_seq_params(
             $design_well,
             {   is_allele             => 1,
                 design_type           => 'conditional',
                 design_cassette_first => 1,
                 recombinase           => [],
             }
        )
    } qr/No cassette found for well/
        ,'throws error when it can not work out cassette for well ';

     throws_ok {
         fetch_well_eng_seq_params(
             $design_well,
             {   is_allele             => 1,
                 design_type           => 'foo',
                 design_cassette_first => 1,
                 recombinase           => [],
                 cassette              => 'moo'
             }
        )
    } qr/Don't know how to generate allele seq/
        ,'throws error when unknown design type used';

    ok my $well = model->retrieve_well( { well_name => 'H03',plate_name => 'ETPCS0004_A' } )
        , 'grab test well';


     ok my ( $method, $params ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 1,
            design_type           => 'conditional',
            design_cassette_first => 1,
            recombinase           => [],
        }
    ), 'call fetch_well_eng_seq_params for standard conditional allele';

    is $method, 'conditional_allele_seq', '.. method is correct';
    is_deeply $params->{u_insertion}, { name => 'pR6K_R1R2_ZP' }, '.. have right cassette in u_insertion slot';
    is_deeply $params->{d_insertion}, { name => 'LoxP' }, '.. have LoxP in d_insertion slot';
    is_deeply $params->{recombinase}, [], '.. no recombinases';

     ok my ( $method2 , $params2 ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 1,
            design_type           => 'conditional',
            design_cassette_first => 0,
            recombinase           => [ 'Cre' ],
        }
    ), 'call fetch_well_eng_seq_params for LoxP first conditional allele';

    is $method2, 'conditional_allele_seq', '.. method is correct';
    is_deeply $params2->{u_insertion}, { name => 'LoxP' }, '.. have LoxP in u_insertion slot';
    is_deeply $params2->{d_insertion}, { name => 'pR6K_R1R2_ZP' }, '.. have cassette in d_insertion slot';
    is_deeply $params2->{recombinase}, [ 'cre' ], '.. have one recombinase';

     ok my ( $method3 , $params3 ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 0,
            design_type           => 'conditional',
            design_cassette_first => 1,
            recombinase           => [],
            cassette              => 'foo'
        }
    ), 'call fetch_well_eng_seq_params for standard conditional vector';

    is $method3, 'conditional_vector_seq', '.. method is correct';
    is_deeply $params3->{u_insertion}, { name => 'foo' }, '.. have specified cassette in u_insertion slot';
    is_deeply $params3->{d_insertion}, { name => 'LoxP' }, '.. have LoxP in d_insertion slot';
    is_deeply $params3->{backbone}, { name => 'R3R4_pBR_amp' }, '.. have backbone information';

     ok my ( $method4 , $params4 ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 0,
            design_type           => 'conditional',
            design_cassette_first => 0,
            recombinase           => [],
            cassette              => 'foo',
            backbone              => 'bar',
        }
    ), 'call fetch_well_eng_seq_params for standard conditional vector';

    is $method4, 'conditional_vector_seq', '.. method is correct';
    is_deeply $params4->{u_insertion}, { name => 'LoxP' }, '.. have LoxP in u_insertion slot';
    is_deeply $params4->{d_insertion}, { name => 'foo' }, '.. have specified cassette in d_insertion slot';
    is_deeply $params4->{backbone}, { name => 'bar' }, '.. have backbone information';

    ok my ( $method5 , $params5 ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 1,
            design_type           => 'deletion',
            design_cassette_first => 1,
            recombinase           => [ ],
        }
    ), 'call fetch_well_eng_seq_params for deletion allele';

    is $method5, 'deletion_allele_seq', '.. method is correct';
    is_deeply $params5->{insertion}, { name => 'pR6K_R1R2_ZP' }, '.. have cassette in insertion slot';

    ok my ( $method6 , $params6 ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 1,
            design_type           => 'insertion',
            design_cassette_first => 1,
            recombinase           => [ ],
        }
    ), 'call fetch_well_eng_seq_params for insertion allele';

    is $method6, 'insertion_allele_seq', '.. method is correct';
    is_deeply $params6->{insertion}, { name => 'pR6K_R1R2_ZP' }, '.. have cassette in insertion slot';

    ok my ( $method7 , $params7 ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 0,
            design_type           => 'deletion',
            design_cassette_first => 1,
            recombinase           => [ ],
        }
    ), 'call fetch_well_eng_seq_params for deletion allele';

    is $method7, 'deletion_vector_seq', '.. method is correct';
    is_deeply $params7->{insertion}, { name => 'pR6K_R1R2_ZP' }, '.. have cassette in insertion slot';

    ok my ( $method8 , $params8 ) = fetch_well_eng_seq_params(
        $well,
        {   is_allele             => 0,
            design_type           => 'insertion',
            design_cassette_first => 1,
            recombinase           => [ ],
        }
    ), 'call fetch_well_eng_seq_params for insertion allele';

    is $method8, 'insertion_vector_seq', '.. method is correct';
    is_deeply $params8->{insertion}, { name => 'pR6K_R1R2_ZP' }, '.. have cassette in insertion slot';
}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

