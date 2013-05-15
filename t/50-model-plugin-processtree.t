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
use DateTime;
use File::Temp ':seekable';

note("Testing process tree methods - descendants");
{

    ok my $paths = model->get_paths_for_well_id_depth_first( { well_id =>850, direction => 1} ), 'retrieved descendant paths for well_id 850';

    my @ref_paths;
    my @path_cmp = ( 850, 851, 852, 853, 854 );
    push @ref_paths, [@path_cmp];

    @path_cmp = ( 850, 851, 852, 1503, 1504 );
    push @ref_paths, [@path_cmp];

    foreach my $check_path ( 0 .. 1 ) {
        my $n = 0;
        foreach my $well ( @{$paths->[$check_path]} ) {
            is $well, $ref_paths[$check_path][$n], "path .. $n matches reference path $check_path:$n";
            ++$n;
        }
    }
	ok $paths = model->get_paths_for_well_id_depth_first( { well_id => 930, direction => 1} ), 'retrieved descendant paths for well_id 930';
    is scalar @{$paths}, 49, '.. 49 paths were returned'; 
	ok $paths = model->get_paths_for_well_id_depth_first( { well_id => 935, direction => 1} ), 'retrieved descendant paths for well_id 935';
    is scalar @{$paths}, 192, '.. 192 paths were returned'; 
}

note("Testing process tree methods - ancestors");
{
    ok my $paths = model->get_paths_for_well_id_depth_first( { well_id =>854, direction => 0} ), 'retrieved ancestors paths for well_id  854';
    my @ref_paths;
    my @path_cmp = reverse ( 850, 851, 852, 853, 854 );
    push @ref_paths, [@path_cmp];

    @path_cmp = reverse ( 850, 851, 852, 1503, 1504 );
    push @ref_paths, [@path_cmp];

    foreach my $check_path ( 0 .. 1 ) {
        my $n = 0;
        foreach my $well ( @{$paths->[$check_path]} ) {
            is $well, $ref_paths[$check_path][$n], "path .. $n matches reference path $check_path:$n";
            ++$n;
        }
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

done_testing();
