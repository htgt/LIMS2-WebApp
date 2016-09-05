#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use FindBin qw($Bin);
print $Bin;
use lib "$Bin/../../../js";

use Test::Class;
use LIMS2::t::js::Admin::Announcements;


Test::Class->runtests;


1;
