#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Test;

ok my $res = model->search_genes( { gene => 'cbx1' } ), 'search_genes cbx1';
is_deeply $res, [ { marker_symbol => 'Cbx1', mgi_accession_id => 'MGI:105369' } ], '...returns expected result';

done_testing;
