#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most tests => 6;
use Try::Tiny;

BEGIN {
    use_ok('LIMS2::Model::Util::DesignTargets', qw( designs_matching_design_target ) );
}

note('Test getting designs for design target');
my $create_design_target_data = test_data( 'design_targets_util.yaml' );

{
    ok my $design_target = model->create_design_target( $create_design_target_data->{design_target_with_design} )
        , 'can create new design target';

    ok my $designs = designs_matching_design_target( model->schema, $design_target )
        , 'can call designs_matching_design_target';

    is scalar( @{ $designs } ), 1, 'We have list of one design';
    my $design = shift @{ $designs };
    is $design->id, 221035, '.. and that design is the correct one';

    is $design->genes->first->gene_id, $design_target->gene_id, 'design target and design have same gene';

}

done_testing();
