#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most tests => 6;

note('Testing the creation designs targets');
my $create_design_target_data = test_data( 'create_design_targets.yaml' );

{

    ok my $design_target = model->create_design_target( $create_design_target_data->{valid_design_target} )
        , 'can create new design target';
    is $design_target->species_id, 'Human', '..has correct species';
    is $design_target->ensembl_exon_id, 'ENSE00002690665', '..has correct exon id';
    is $design_target->marker_symbol, 'ABL1', '..has correct marker symbol';
    is $design_target->gene_id, 'HGNC:76', '..has correct gene name';

    throws_ok{
        model->create_design_target( $create_design_target_data->{valid_design_target} )
    } qr/Design target already exists on same build for exon/
    , 'throws error if design target with same exon id and build already exists' ;

}

done_testing;
