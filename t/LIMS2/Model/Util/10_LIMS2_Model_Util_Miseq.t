#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($FATAL);
    if (defined $ENV{'LIMS2_TEST_DEBUG_LOGGING'}) {
        Log::Log4perl->easy_init( { level => $DEBUG } );
    }
}

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use Test::Class;
use LIMS2::t::Model::Util::Miseq;

Test::Class->runtests;

1;

__END__

