#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use Hash::MoreUtils qw( slice );
use LIMS2::Model::DBConnect;

use_ok 'LIMS2::Model';

done_testing;
