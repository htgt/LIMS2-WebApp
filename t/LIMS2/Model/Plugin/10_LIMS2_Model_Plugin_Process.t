#!/usr/bin/env perl
# 10_LIMS2_Model_Plugin_Process.t

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

use Test::Class;
use LIMS2::t::Model::Plugin::Process;

=head1 NAME

10_LIMS2_Model_Plugin_Process.t - Test file for testing the perl module 'LIMS2::Model::Plugin::Process'

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 AUTHOR

Lars G. Erlandsen

=cut

Test::Class->runtests;


1;

__END__

