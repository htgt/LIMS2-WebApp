package LIMS2::t::Model::Plugin::ProcessTree;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model qw(get_paths_for_well_id_depth_first);
use LIMS2::Model::Plugin::ProcessTree;

use LIMS2::Test;
use Try::Tiny;
use DateTime;
use File::Temp ':seekable';

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/ProcessTree.pm - test class for LIMS2::Model::Plugin::ProcessTree

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

sub all_tests  : Test(29)
{
    note("Testing process tree methods - descendants");
    {   

	ok my $paths = model->get_paths_for_well_id_depth_first( { well_id =>850, direction => 1} ), 'retrieved descendant paths for well_id 850'; 

	my $paths_count = scalar ( @{$paths} );
	ok $paths_count = 2, '..correct number of descendant paths';

	my $path_cmp_1 = [ 850, 851, 852, 853, 854 ];
	my $path_cmp_2 = [ 850, 851, 852, 1503, 1504 ];

	my $comp = Array::Compare->new;

	foreach my $path ( @{ $paths } ) {
	    my $n = 0;
	    ok $comp->compare( $path_cmp_1, $path ) || $comp->compare( $path_cmp_2, $path ), "path matches reference path";
	    ++$n;
	}   
	    ok $paths = model->get_paths_for_well_id_depth_first( { well_id => 930, direction => 1} ), 'retrieved descendant paths for well_id 930';
	is scalar @{$paths}, 49, '.. 49 paths were returned';
	    ok $paths = model->get_paths_for_well_id_depth_first( { well_id => 935, direction => 1} ), 'retrieved descendant paths for well_id 935';
	is scalar @{$paths}, 192, '.. 192 paths were returned';
    }

    note("Testing process tree methods - ancestors");
    {   
	ok my $paths = model->get_paths_for_well_id_depth_first( { well_id =>854, direction => 0} ), 'retrieved ancestors paths for well_id  854'; 

	my $paths_count = scalar ( @{$paths} );
	ok $paths_count = 2, '..correct number of ancestor paths';

	my $path_cmp_1 = [ reverse ( 850, 851, 852, 853, 854 ) ];
	my $path_cmp_2 = [ reverse ( 850, 851, 852, 1503, 1504 ) ];

	my $comp = Array::Compare->new;

	foreach my $path ( @{ $paths } ) {
	    my $n = 0;
	    ok $comp->compare( $path_cmp_1, $path ) || $comp->compare( $path_cmp_2, $path ), "path matches reference path";
	    ++$n;
	}

	    ok $paths = model->get_paths_for_well_id_depth_first( { well_id => 1623, direction => 0} ), 'retrieved ancestor paths for well_id 1623';
	is scalar @{$paths}, 2, '.. 2 paths were returned';
	    ok $paths = model->get_paths_for_well_id_depth_first( { well_id => 939, direction => 0} ), 'retrieved ancestor paths for well_id 939';
	is scalar @{$paths}, 1, '.. 1 path was returned';
    }

    note('Testing process tree design retrieval');
    {   

	my @well_list = ( 850, 851, 852, 853, 854 );
	ok my $design_data = model->get_design_data_for_well_id_list( \@well_list ), 'retrieved design data for well list';
	is $design_data->{'850'}->{'design_id'}, 84231, '.. design ID is correct';
	is $design_data->{'854'}->{'design_well_id'}, 850, '.. design well ID is correct';
	is $design_data->{'854'}->{'gene_id'}, 'MGI:1917722', '.. gene_id is correct';
    }

    note('Testing process tree unique child well resultset from design well parent');
    {  

	my $design_well_id = 930;
	ok my $rs = model->get_wells_for_design_well_id (
	{ 
	   'well_id' => $design_well_id,
	}), 'invoked get_wells_for_design_well_id for design well 930';

	my $num_wells = scalar $rs;
	is scalar $rs, 104, '.. 104 unique well objects were returned';
	my @well_list;
	while ( my $well = $rs->next ) {
	    push @well_list, $well->id;
	}

	@well_list = sort { $a <=> $b } @well_list;

    #    print join q{,}, @well_list ; 
    #    print "\n";

	is $well_list[0], 930, 'first unique well is 930';
	is $well_list[10], 1524, 'tenth unique well is 1524';
	is $well_list[-1], 1617, 'last unique well is 1617';
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

