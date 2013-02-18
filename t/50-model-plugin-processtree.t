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

note("Testing process tree methods");
{

    ok my $paths = model->get_paths_for_well_id_depth_first( 850 ), 'got paths for well_id 850';
use Data::Dumper;

my @path_cmp[0][0 .. 4] = ( 850, 851, 852, 853, 854 );
@path_cmp[1][0 .. 4] = ( 850, 851, 852, 1503, 1504 );

print Dumper( $paths );

print Dumper( $path_cmp );

    my $n = 0;
    foreach my $well ( @{$paths->[0]} ) {
        'Well ' . $n++ . ' of trail ' . $well. "\n";
    }
	ok $paths = model->get_paths_for_well_id_depth_first( 930 ), 'got paths for well_id 930';
print Dumper( $paths );
	ok $paths = model->get_paths_for_well_id_depth_first( 935 ), 'got paths for well_id 935';
print Dumper( $paths );
}

done_testing();
