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
use LIMS2::t::Model::Util::EPPipelineIIPlate;

=head1 NAME

#10_LIMS2_Model_Util_Crisprs.t - Test file for testing the perl module 'LIMS2::Model::Util::Crisprs'

=head1 DESCRIPTION

Test module structured for running under Test::Class

=cut

Test::Class->runtests;


1;

__END__

