#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use Test::Class;
use LIMS2::t::Model::Util::PrimerFinder;

Test::Class->runtests;

1;
