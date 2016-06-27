#!/usr/bin/env perl
# 10_LIMS2_Model_Util_ImportSequencing.t

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
};

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use Test::Class;
use LIMS2::t::Model::Util::ImportSequencing;


Test::Class->runtests;


1;

__END__

