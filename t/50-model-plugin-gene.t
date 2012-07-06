#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Test;
use Const::Fast;

const my %TEST_DATA => ( marker_symbol => 'Cbx1', mgi_accession_id => 'MGI:105369' );

const my @SEARCHES => (
    { gene             => $TEST_DATA{marker_symbol} },
    { marker_symbol    => $TEST_DATA{marker_symbol} },
    { mgi_accession_id => $TEST_DATA{mgi_accession_id} }
);

for my $search ( @SEARCHES ) {
    ok my $res = model->search_genes( $search ), 'search_genes';
    is_deeply $res, [ \%TEST_DATA ], '...returns expected result';
}

done_testing;
