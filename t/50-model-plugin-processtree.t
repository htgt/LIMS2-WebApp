#!/usr/bin/env perl -d

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

print Dumper( $paths );

	ok $paths = model->get_paths_for_well_id_depth_first( 930 ), 'got paths for well_id 930';

	ok $paths = model->get_paths_for_well_id_depth_first( 935 ), 'got paths for well_id 935';

}

done_testing();
