#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most tests => 24;
use Try::Tiny;

BEGIN {
    use_ok('LIMS2::Model::Util::DesignTargets'
        , qw( designs_matching_design_target_via_exon_name
              designs_matching_design_target_via_coordinates
              crisprs_for_design_target
              find_design_targets
              bulk_designs_for_design_targets
    ) );
}

my $design_target1;
my $design_target2;

note('Test getting designs for design target via exon names');
my $create_design_target_data = test_data( 'design_targets_util.yaml' );

{
    ok $design_target1 = model->create_design_target( $create_design_target_data->{design_target_with_design} )
        , 'can create new design target';

    ok my $designs_via_exon = designs_matching_design_target_via_exon_name( model->schema, $design_target1 )
        , 'can call designs_matching_design_target';

    is scalar( @{ $designs_via_exon } ), 1, 'We have list of one design';
    my $design = shift @{ $designs_via_exon };
    is $design->id, 221035, '.. and that design is the correct one';

    is $design->genes->first->gene_id, $design_target1->gene_id, 'design target and design have same gene';

}

note('Test getting designs for design target via target region coordiantes');
{

    ok my $designs_via_coords = designs_matching_design_target_via_coordinates( model->schema, $design_target1 )
        , 'can call designs_matching_design_target';

    is scalar( @{ $designs_via_coords } ), 1, 'We have list of one design';
    my $design = shift @{ $designs_via_coords };
    is $design->id, 221035, '.. and that design is the correct one';

    is $design->genes->first->gene_id, $design_target1->gene_id, 'design target and design have same gene';

}

note('Find crisprs for a design target');

{
    ok $design_target2 = model->create_design_target( $create_design_target_data->{design_target_with_crispr} )
        , 'can create new design target';

    ok my $crisprs = crisprs_for_design_target( model->schema, $design_target2 )
        , 'can call crisprs_for_design_target';

    is scalar( @{ $crisprs } ), 1, '.. found one crispr';
    is $crisprs->[0]->id, 113, '.. crispr has expected id';

}

note('Search for design targets by gene ids');

{

    ok my $design_targets = find_design_targets( model->schema, [ 'MGI:1111111' ], 'Mouse' )
        ,'can call find_design_targets';

    is scalar( @{ $design_targets } ), 1, '..we have one design target';
    my $dt = shift @{ $design_targets };
    is $dt->gene_id, 'MGI:1111111', '.. design target has right gene_id';
    is $dt->species_id, 'Mouse', '.. design target has right species';

}

note('Find designs for multiple design targets');

{
    my $design_targets = [ $design_target1, $design_target2 ];

    ok my $data = bulk_designs_for_design_targets( model->schema, $design_targets, 'Mouse' )
        , 'can call bulk_designs_for_design_targets';

    ok my $dt1_designs = $data->{ $design_target1->id }, 'have array of designs for design target 1';
    is scalar( @{ $dt1_designs } ), 1, '.. have one matching design';
    is $dt1_designs->[0]->id, 221035, '.. and that design is the correct one';

    ok my $dt2_designs = $data->{ $design_target2->id }, 'have array of designs for design target 2';
    is scalar( @{ $dt2_designs } ), 0, '.. have no matching design';
}

done_testing();
