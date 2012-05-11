#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Model::Test;

can_ok __PACKAGE__, 'model';

done_testing;
