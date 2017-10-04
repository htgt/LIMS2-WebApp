#!/usr/bin/env perl
# 10_LIMS2_WebApp_Controller_User_CrisprBrowseAndStore.t

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";

use Test::Class;
use LIMS2::t::WebApp::Controller::User::CrisprBrowseAndStore;
use LIMS2::Model::Util::CrisprOrderAndStorage;

Test::Class->runtests;


1;

__END__
