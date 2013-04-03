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
    use_ok('LIMS2::Model::Util::BacsForDesign', qw( bacs_for_design ) );

    # Set default mouse assembly to NCBMIM37 for these test.
    # Because the bac clones in the fixture data have locus info only for this assembly
    ok my $mouse_default_assembly
        = model->schema->resultset('SpeciesDefaultAssembly')->find( { species_id => 'Mouse' } )
        , 'can grab mouse species default assembly';
    ok $mouse_default_assembly->update( { assembly_id => 'NCBIM37' } )
        , 'can change default to NCBIM37';
}

note('Test bacs_for_design');

{
    ok my $design = model->retrieve_design( { id => 94427  } ), 'can grab design 94427';
    ok my $bacs = bacs_for_design( model, $design ), 'can call bacs_for_design';
    my @expected_bacs = qw(
        RP24-260C10
        RP24-236G5
        RP24-72G5
        RP24-369G5
    );
    is_deeply $bacs, \@expected_bacs, 'we have expected bacs for design';
}

note( 'Test get_bac_clones' );

{
    ok my $design = model->retrieve_design( { id => 94427  } ), 'can grab design 94427';
    ok my $bacs
        = LIMS2::Model::Util::BacsForDesign::get_bac_clones( model, $design, 'NCBIM37', 'black6' )
        , 'get_bac_clones returns data';

    isa_ok $bacs->[0], 'LIMS2::Model::Schema::Result::BacClone';

    ok my @expected_bacs = model->schema->resultset( 'BacClone' )->search(
        {
           bac_library_id     => 'black6',
           'loci.chr_id'      => 3182,
           'loci.chr_start'   => { '<=' => 100760042 },
           'loci.chr_end'     => { '>=' => 100773657 },
           'loci.assembly_id' => 'NCBIM37',
        },
        {
            join => 'loci',
        }
    ), 'can grab expected bac clones';

    my $expected_clone_names = [ map{ $_->name } @expected_bacs ];
    my $clone_names = [ map{ $_->name } @{ $bacs } ];
    is_deeply $expected_clone_names, $clone_names, 'we have expected clones';

    throws_ok{
        LIMS2::Model::Util::BacsForDesign::get_bac_clones( model, $design, 'NCBIM37', '129' ),
    } qr/No bacs found for design/
        , 'throws error if no bacs found for a design';
}

note( 'Test target_start' );

{
    ok my $design = model->retrieve_design( { id => 94427  } ), 'can grab design 94427';
    ok my $target_start = LIMS2::Model::Util::BacsForDesign::target_start( $design )
        , 'target_start returns data';

    is $target_start, $design->target_region_start - 6000, 'correct target start value';
}

note( 'Test target_end' );

{
    ok my $design = model->retrieve_design( { id => 94427  } ), 'can grab design 94427';
    ok my $target_end = LIMS2::Model::Util::BacsForDesign::target_end( $design )
        , 'target_end returns data';

    is $target_end, $design->target_region_end + 6000, 'correct target end value';
}

note( 'Test sort_bacs_by_size' );

{
    ok my $design = model->retrieve_design( { id => 94427  } ), 'can grab design 94427';
    ok my $bacs
        = LIMS2::Model::Util::BacsForDesign::get_bac_clones( model, $design, 'NCBIM37', 'black6' )
        , 'get_bac_clones returns data';
    my @bac_names = map{ $_->name } @{ $bacs };

    ok my $sorted_bac_names = LIMS2::Model::Util::BacsForDesign::sort_bacs_by_size( $bacs, 'NCBIM37' )
        , 'can call sort_bacs_by size';

    my @expected_bacs = qw(
        RP24-260C10
        RP24-236G5
        RP24-72G5
        RP24-369G5
    );
    is_deeply $sorted_bac_names, \@expected_bacs
        , 'ordered bacs by closeness to preferred bac size';
}

note( 'Test order_bacs' );

{
    my @bac_names = qw(
        RP24-359K20
        RP23-186E21
        RP24-322P23
        RP24-549E8
    );
    ok my @expected_bacs = model->schema->resultset( 'BacClone' )->search(
        {
            name => { 'IN' => \@bac_names }
        },
    ), 'can grab expected bac clones';

    ok my $ordered_bac_names
        = LIMS2::Model::Util::BacsForDesign::order_bacs( \@expected_bacs, 'NCBIM37' )
        , 'can call order_bacs';

    my @expected_ordered_bac_names = qw(
        RP24-322P23
        RP24-549E8
        RP24-359K20
        RP23-186E21
    );
    is_deeply $ordered_bac_names, \@expected_ordered_bac_names
        , 'returns bac names in expected order, RP24 bacs first';
}

note( 'Test Invalid Design' );

{
    ok my $design = model->retrieve_design( { id => 94427  } ), 'can grab design 94427';
    ok my $U3_oligo = model->schema->resultset( 'DesignOligo' )->find(
        {
            design_id => 94427,
            design_oligo_type_id => 'U3',
        }
    ), 'can grab design 94427 U3 oligo';
    ok $U3_oligo->loci->delete, 'can delete U3 oligo loci';
    ok $U3_oligo->delete, 'can delete U3 oligo';

    throws_ok {
        bacs_for_design( model, $design )
    } qr/Can not find design target region end/
        , 'throws error when we can not find design target region start value';

}

done_testing();
