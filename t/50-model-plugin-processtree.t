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

    ok my $paths = model->get_paths_for_well_id_depth_first( { well_id =>850, direction => 0} ), 'retrieved ancestors paths for well_id 850';

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

done_testing();
