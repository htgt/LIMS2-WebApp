#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

{
    ok my $design = model->retrieve_design( { id => 95 } ), 'retrieve design id=95';
    isa_ok $design, 'LIMS2::Model::Schema::Result::Design';    
}

{
    ok my $designs = model->list_designs_for_gene( { gene => 'MGI:1915248' } ), 'list designs by MGI accession';
    isa_ok $designs, ref [];
    ok @{$designs} > 0, '...the list is not empty';
    isa_ok $_, 'LIMS2::Model::Schema::Result::Design' for @{$designs};    
}

{
    ok my $designs = model->list_designs_for_gene( { gene => 'MGI:1915248', type => 'conditional' } ),
        'list designs by MGI accession and design type conditional';
    isa_ok $designs, ref [];
    ok @{$designs} > 0, '...the list is not empty';
    isa_ok $_, 'LIMS2::Model::Schema::Result::Design' for @{$designs};    
}

{
    ok my $designs = model->list_designs_for_gene( { gene => 'MGI:1915248', type => 'deletion' } ),
        'list designs by MGI accession and design type deletion';
    is @{$designs}, 0, 'returns no designs';
}

{
    ok my $designs = model->list_designs_for_gene( { gene => 'Fam134c' } ), 'list designs by marker';
    ok @{$designs} > 0, '...returns a non-empty list';
    ok grep( { $_->id == 95 } @{$designs} ), '...returns the expected design';
}

{
    ok my $designs = model->list_candidate_designs_for_mgi_accession( { mgi_accession_id => 'MGI:1915248' } ),
        'list candidate designs for MGI accession';
    isa_ok $designs, ref [];
    ok grep( { $_->id == 95 } @{$designs} ), '...returns the expected design';
}

    



    
    

done_testing;

                               
