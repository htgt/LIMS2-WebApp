#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use List::MoreUtils qw( uniq );
use Text::CSV;
use Const::Fast;

const my @COLUMNS => qw(
                           mgi_accession_id marker_symbol plate_name well_name design_id cassette backbone recombinase accepted?
                   );

my $csv = Text::CSV->new( { eol => "\n" } );

$csv->print( \*STDOUT, \@COLUMNS );

my $model = LIMS2::Model->new( user => 'tasks' );

my $final_vectors_rs = $model->schema->resultset( 'Well' )->search(
    {
        'plate.type_id' => 'FINAL'
    },
    {
        join => 'plate'
    }
);

while ( my $well = $final_vectors_rs->next ) {
    my $design = $well->design;
    my @mgi_accessions = map { $_->gene_id } $design->genes;    
    my @marker_symbols = uniq map { $_->{marker_symbol} }
        map { @{ $model->search_genes( { gene => $_ } ) } } @mgi_accessions;
    
    $csv->print( \*STDOUT, [
        join( '/', @mgi_accessions ),
        join( '/', @marker_symbols ),
        $well->plate->name,
        $well->name,
        $design->id,
        $well->cassette,
        $well->backbone,
        join( '/', @{$well->recombinases} ),
        ( $well->is_accepted ? 'yes': 'no' )
    ] );
}

