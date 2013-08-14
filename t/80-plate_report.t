#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

my $mech = mech();

{
    note('Can view plate report');

    $mech->get_ok( '/user/report/sync/DesignPlate?plate_id=939' );
    $mech->content_contains('Design Plate 187');
    $mech->content_contains('Baz2b');
}

done_testing;
