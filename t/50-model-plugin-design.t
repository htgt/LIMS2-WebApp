#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

{
    ok my $design = model->retrieve_design( { id => 84231 } ), 'retrieve design id=84231';
    isa_ok $design, 'LIMS2::Model::Schema::Result::Design';
    can_ok $design, 'as_hash';
    ok my $h1 = $design->as_hash(), 'as hash, with relations';
    isa_ok $h1, ref {};
    ok $h1->{genotyping_primers}, '...has genotyping primers';
    ok my $h2 = $design->as_hash(1), 'as_hash, suppress relations';
    ok !$h2->{genotyping_primers}, '...no genotyping primers';
}

{
    ok my $designs = model->list_assigned_designs_for_gene( { species => 'Mouse', gene_id => 'MGI:94912' } ), 'list assigned designs by MGI accession';
    isa_ok $designs, ref [];
    ok @{$designs} > 0, '...the list is not empty';
    isa_ok $_, 'LIMS2::Model::Schema::Result::Design' for @{$designs};
}

{
    ok my $designs = model->list_assigned_designs_for_gene( { species => 'Mouse', gene_id => 'MGI:106032', type => 'conditional' } ),
        'list assigned designs by MGI accession and design type conditional';
    isa_ok $designs, ref [];
    ok @{$designs} > 0, '...the list is not empty';
    isa_ok $_, 'LIMS2::Model::Schema::Result::Design' for @{$designs};
}

{
    ok my $designs = model->list_assigned_designs_for_gene( { species => 'Mouse', gene_id => 'MGI:1915248', type => 'deletion' } ),
        'list assigned designs by MGI accession and design type deletion';
    is @{$designs}, 0, 'returns no designs';
}

{
    ok my $designs = model->list_candidate_designs_for_gene( { species => 'Mouse', gene_id => 'MGI:94912' } ),
        'list candidate designs for MGI accession';
    isa_ok $designs, ref [];
    ok grep( { $_->id == 170606 } @{$designs} ), '...returns the expected design';
}

done_testing;
