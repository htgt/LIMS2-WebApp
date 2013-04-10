#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most;
use Try::Tiny;

note('Test getting reverse complimented oligo sequence');

{
    ok my $design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54767 } )
        ,' can find design oligom, 54767, G5';

    my $oligo_seq = 'ACCTGGAGACCAGGAAATGGTGAAGTACAACAGTACATATTTTAAATTTT';
    is $design_oligo->seq, $oligo_seq , 'correct oligo seq';
    my $revcomp_oligo_seq = _revcomp_seq( $oligo_seq );

    is $design_oligo->revcomp_seq, $revcomp_oligo_seq, 'have correct reverse complimented sequence';

    ok $design_oligo->update( { seq => 'ATCGN' } ), 'can update design oligo seq, with N base';

    is $design_oligo->revcomp_seq, 'NCGAT', 'correct reverse complimented seq with N';

    ok $design_oligo->update( { seq => 'XXX1123' } ), 'can update design oligo seq with nonsense data';

    throws_ok{
        $design_oligo->revcomp_seq
    } qr/Error working out revcomp of sequence/, 'throws error when trying to revcomp invalid seq';
}

note( 'Testing append_seq' );

{
    ok my $u5_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54768 } )
        ,' can find design oligo, 54768, U5';

    is $u5_design_oligo->append_seq, 'AAGGCGCATAACGATACCAC', 'correct append seq for U5 oligo, ins-del design';
    is $u5_design_oligo->append_seq( 'artificial-intron' ), 'GTGAGTGTGCTAGAGGGGGTG'
        ,'correct append seq for U5 oligo, art intron design';

    throws_ok{
        $u5_design_oligo->append_seq( 'blah' )
    } qr/Do not know append sequences for blah designs/
        ,'throws error when sending in unknown design type';

    ok my $u3_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54763 } )
        ,' can find design oligo, 54763, U3';

    throws_ok{
        $u3_design_oligo->append_seq( 'deletion' )
    } qr/Undefined append sequence for U3 oligo on deletion design/
        ,'throws error when sending in unknown design type';

    is $u3_design_oligo->append_seq, 'CCGCCTACTGCGACTATAGA', 'correct U3 append seq for KO design';

}

note( 'Test oligo_order_seq, -ve stranded design' );

{
    # -ve Stranded design oligos, 88505
    ok my $u5_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54768 } )
        ,' can find design oligo, 54768, U5';
    ok my $u5_append_seq = $u5_design_oligo->append_seq, 'can grab U5 append seq';

    #U5 oligo on -ve stranded design must be revcomped
    my $expected_u5_order_seq = _revcomp_seq( $u5_design_oligo->seq );
    $expected_u5_order_seq .= $u5_append_seq;
    is $u5_design_oligo->oligo_order_seq, $expected_u5_order_seq, 'got expected U5 order seq';


    ok my $d3_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54769 } )
        ,' can find design oligo, 54769, D3';
    ok my $d3_append_seq = $d3_design_oligo->append_seq, 'can grab D3 append seq';

    #D3 oligo on -ve stranded design must NOT be revcomped
    my $expected_d3_order_seq = $d3_design_oligo->seq . $d3_append_seq;
    is $d3_design_oligo->oligo_order_seq, $expected_d3_order_seq, 'got expected D3 order seq';

}

note( 'Test oligo_order_seq, +ve stranded design' );

{
    # +ve Stranded design oligos, 85512
    ok my $u5_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54772 } )
        ,' can find design oligo, 54768, U5';
    ok my $u5_append_seq = $u5_design_oligo->append_seq, 'can grab U5 append seq';

    #U5 oligo on +ve stranded design must NOT be revcomped
    my $expected_u5_order_seq = $u5_design_oligo->seq . $u5_append_seq;
    is $u5_design_oligo->oligo_order_seq, $expected_u5_order_seq, 'got expected U5 order seq';


    ok my $d3_design_oligo = model->schema->resultset( 'DesignOligo' )->find( { id => 54773 } )
        ,' can find design oligo, 54769, D3';
    ok my $d3_append_seq = $d3_design_oligo->append_seq, 'can grab D3 append seq';

    #D3 oligo on +ve stranded design must be revcomped
    my $expected_d3_order_seq = _revcomp_seq( $d3_design_oligo->seq );
    $expected_d3_order_seq .= $d3_append_seq;
    is $d3_design_oligo->oligo_order_seq, $expected_d3_order_seq, 'got expected D3 order seq';

}

sub _revcomp_seq {
    my $seq = shift;

    my $revcomp_oligo_seq = reverse( $seq );
    $revcomp_oligo_seq =~ tr/ATCG/TAGC/;

    return $revcomp_oligo_seq;
}

done_testing();
