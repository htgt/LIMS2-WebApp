#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :levels );
    Log::Log4perl->easy_init( $DEBUG );
}

use Test::Most;
use LIMS2::Model::Test;

can_ok __PACKAGE__, 'model';

done_testing;
