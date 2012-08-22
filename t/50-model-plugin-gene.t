#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use LIMS2::Test;
use Const::Fast;

{
    const my %GENE_DATA => ( gene_id => 'MGI:105369', gene_symbol => 'Cbx1' );
    const my @SEARCHES => (
        { species => 'Mouse', search_term => 'Cbx1' },
        { species => 'Mouse', search_term => 'MGI:105369' },
        { species => 'Mouse', search_term => 'ENSMUSG00000018666' }
    );
    for my $search ( @SEARCHES ) {
        ok my $searched = model->search_genes( $search ), 'search_genes';
        is_deeply $searched, [ \%GENE_DATA ], '...returns expected result';
        ok my $retrieved = model->retrieve_gene( $search ), 'retrieve_gene';
        is_deeply $retrieved, \%GENE_DATA, '...returns expected result';
    }
}

{
    const my %GENE_DATA => ( gene_id => 'ENSG00000108511', gene_symbol => 'HOXB6' );
    for my $search_term ( values %GENE_DATA ) {
        is_deeply model->retrieve_gene( { species => 'Human', search_term => $search_term } ), \%GENE_DATA,
            "Retrieve gene $search_term returns the expected result";
    }
}

{
    ok my $searched = model->search_genes( { species => 'Human', search_term => 'HOXB6' } ), 'search human gene';
    is_deeply $searched, [ {  gene_id => 'ENSG00000108511', gene_symbol => 'HOXB6' } ],
        '.. returns expected results';
}

done_testing;
