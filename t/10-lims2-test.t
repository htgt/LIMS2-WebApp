#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :levels );
    Log::Log4perl->easy_init( $DEBUG );
}

use Test::Most;
use LIMS2::Test;

for my $method ( qw( model mech unauthenticated_mech test_data ) ) {    
    can_ok __PACKAGE__, $method;
}

done_testing;
