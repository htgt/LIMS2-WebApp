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

BEGIN {
    use_ok('LIMS2::Model::Util::DesignInfo' );
}

note('Test Valid Conditional -ve Stranded Design');

{
    ok my $design = model->retrieve_design( { id => 81136  } ), 'can grab design 81136';
    ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ), 'can grab design info object';
    isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

    is $di->chr_strand, -1, 'strand correct';
    is $di->chr_name, 15, 'chromosome correct'; 
    # D5 start
    is $di->target_region_start, 53719453, 'correct target region start';
    # U3 end
    is $di->target_region_end, 53720128, 'correct target region end';

    ok my $oligos = $di->oligos, 'can grab oligos hash';
    for my $oligo_type ( qw( G5 U5 U3 D5 D3 G3 ) ) {
        ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
    }
}

note('Test Valid Conditional +ve Stranded Design');

{
    ok my $design = model->retrieve_design( { id => 39833  } ), 'can grab design 39833';
    ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ), 'can grab design info object';
    isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

    is $di->chr_strand, 1, 'strand correct';
    is $di->chr_name, 1, 'chromosome correct'; 
    # U3 start
    is $di->target_region_start, 134595413, 'correct target region start';
    # D5 end
    is $di->target_region_end, 134596081, 'correct target region end';

    ok my $oligos = $di->oligos, 'can grab oligos hash';
    for my $oligo_type ( qw( G5 U5 U3 D5 D3 G3 ) ) {
        ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
    }
}

note('Test Valid Conditional -ve Stranded Deletion');

{
    ok my $design = model->retrieve_design( { id => 88505  } ), 'can grab design 88505';
    ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ), 'can grab design info object';
    isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

    is $di->chr_strand, -1, 'strand correct';
    is $di->chr_name, 7, 'chromosome correct'; 
    # D3 end
    is $di->target_region_start, 122093614, 'correct target region start';
    # U5 start
    is $di->target_region_end, 122096800, 'correct target region end';

    ok my $oligos = $di->oligos, 'can grab oligos hash';
    for my $oligo_type ( qw( G5 U5 D3 G3 ) ) {
        ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
    }
}

note('Test Valid Conditional +ve Stranded Deletion');

{
    ok my $design = model->retrieve_design( { id => 88512  } ), 'can grab design 88512';
    ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ), 'can grab design info object';
    isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

    is $di->chr_strand, 1, 'strand correct';
    is $di->chr_name, 18, 'chromosome correct'; 
    # U5 end
    is $di->target_region_start, 60956803, 'correct target region start';
    # D3 start
    is $di->target_region_end, 60964117, 'correct target region end';

    ok my $oligos = $di->oligos, 'can grab oligos hash';
    for my $oligo_type ( qw( G5 U5 D3 G3 ) ) {
        ok exists $oligos->{$oligo_type}, "have $oligo_type oligo";
    }
}

note( 'Test Invalid Design' );

{
    ok my $design = model->retrieve_design( { id => 81136  } ), 'can grab design 81136';
    ok my $G5_oligo = model->schema->resultset( 'DesignOligo' )->find(
        {
            design_id => 81136,
            design_oligo_type_id => 'G5',
        }
    ), 'can grab design 81136 G5 oligo';

    ok my $default_assembly_id = $design->species->default_assembly->assembly_id
        , 'can grab designs default assembly'; 
    ok my $g5_locus = $G5_oligo->search_related( 'loci', { assembly_id => $default_assembly_id } )->first
        , 'can grab g5 oligos current locus object';

    ok $g5_locus->update( { chr_strand => 1, chr_id => 3172 } ), 'update G5 locus with incorrect info';

    ok my $di = LIMS2::Model::Util::DesignInfo->new( { design => $design } ), 'can grab design info object';
    isa_ok $di, 'LIMS2::Model::Util::DesignInfo';

    throws_ok {
        $di->chr_strand
    } qr/Design 81136 oligos have inconsistent strands/
        , 'throws error when getting design strand, we have mismatch';

    throws_ok {
        $di->chr_name
    } qr/Design 81136 oligos have inconsistent chromosomes/
        , 'throws error when getting design strand, we have mismatch';

}

done_testing();
