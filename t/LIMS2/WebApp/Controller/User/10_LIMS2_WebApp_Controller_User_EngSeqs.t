#!/usr/bin/env perl
use strict;

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";

use LIMS2::t::WebApp::Controller::User::EngSeqs;

Test::Class->runtests;

1;

__END__

