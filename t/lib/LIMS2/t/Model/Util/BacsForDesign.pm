package LIMS2::t::Model::Util::BacsForDesign;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::BacsForDesign;

use LIMS2::Test;
use Try::Tiny;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/BacsForDesign.pm - test class for LIMS2::Model::Util::BacsForDesign

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

sub all_tests  : Test(35)
{

    {
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
	ok my $design = model->c_retrieve_design( { id => 94427  } ), 'can grab design 94427';
	ok my $bacs = bacs_for_design( model, $design ), 'can call bacs_for_design';
	my @expected_bacs = qw(
	    RP24-260C10
	    RP24-236G5
	    RP24-72G5
	    RP24-369G5
	);
	is_deeply $bacs, \@expected_bacs, 'we have expected bacs for design';

	ok my $design2 = model->c_retrieve_design( { id => 170606  } ), 'can grab design 170606';
	throws_ok{
	    bacs_for_design( model, $design2 )
	} qr/No valid bacs/
	    ,'throws error when design has no valid bacs, RP24 or RP23';
    }

    note( 'Test get_bac_clones' );

    {
	ok my $design = model->c_retrieve_design( { id => 94427  } ), 'can grab design 94427';
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
	ok my $design = model->c_retrieve_design( { id => 94427  } ), 'can grab design 94427';
	ok my $target_start = LIMS2::Model::Util::BacsForDesign::target_start( $design )
	    , 'target_start returns data';

	is $target_start, $design->target_region_start - 6000, 'correct target start value';
    }

    note( 'Test target_end' );

    {
	ok my $design = model->c_retrieve_design( { id => 94427  } ), 'can grab design 94427';
	ok my $target_end = LIMS2::Model::Util::BacsForDesign::target_end( $design )
	    , 'target_end returns data';

	is $target_end, $design->target_region_end + 6000, 'correct target end value';
    }
    note( 'Test sort_bacs_by_size' );

    {
	ok my $design = model->c_retrieve_design( { id => 94427  } ), 'can grab design 94427';
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
	    RP24-78L21
	);
	ok my @expected_bacs = model->schema->resultset( 'BacClone' )->search(
	    {
		name => { 'IN' => \@bac_names }
	    },
	), 'can grab expected bac clones';

	ok my $ordered_bac_names
	    = LIMS2::Model::Util::BacsForDesign::order_bacs( \@expected_bacs, 'NCBIM37' )
	    , 'can call order_bacs';

	# RP24 clones first, only 4
	my @expected_ordered_bac_names = qw(
	    RP24-322P23
	    RP24-549E8
	    RP24-359K20
	    RP24-78L21
	);
	is_deeply $ordered_bac_names, \@expected_ordered_bac_names
	    , 'returns bac names in expected order, RP24 bacs first';

	ok my $design = model->c_retrieve_design( { id => 170606  } ), 'can grab design 170606';
	ok my $bacs
	    = LIMS2::Model::Util::BacsForDesign::get_bac_clones( model, $design, 'NCBIM37', 'black6' )
	    , 'get_bac_clones returns data';
	throws_ok{
	    LIMS2::Model::Util::BacsForDesign::order_bacs( $bacs, 'NCBIM37', 170606 )
	} qr/No valid bacs/
	    ,'throws error when design has no valid bacs, RP24 or RP23';
    }

    note( 'Test Invalid Design' );

    {
	ok my $design = model->c_retrieve_design( { id => 94427  } ), 'can grab design 94427';
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

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

