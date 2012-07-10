#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use List::MoreUtils qw( uniq );
use Text::CSV;
use Const::Fast;

const my @COLUMNS => qw(
                           mgi_accession_id marker_symbol design_id design_well final_vector_well final_vector_created cassette backbone recombinase cassette_type accepted?
                   );

my $csv = Text::CSV->new( { eol => "\n" } );

$csv->print( \*STDOUT, \@COLUMNS );

my $model = LIMS2::Model->new( user => 'tasks' );

my $gene_design_rs = $model->schema->resultset( 'GeneDesign' )->search_rs(
    { 'well.id' => { '!=', undef } },
    {
        prefetch => [ { 'design' => { 'process_designs' => { 'process' => { 'process_output_wells' => { 'well' => 'plate' } } } } } ]
    }
);

while ( my $gene_design = $gene_design_rs->next ) {
    my $gene_id   = $gene_design->gene_id;
    my $design_id = $gene_design->design_id;
    my @design_wells = map { $_->output_wells } $gene_design->design->processes;
    for my $design_well ( @design_wells ) {
        my %attrs = (  gene_id => $gene_id, design_id => $design_id, design_well => $design_well, recombinase => [] );        
        my @final_vectors = collect_final_vectors( $design_well, $design_well->descendants, \%attrs );
        for my $vector ( @final_vectors ) {
            $csv->print(
                \*STDOUT, [
                    $vector->{gene_id},
                    $model->retrieve_gene( { gene => $vector->{gene_id} } )->{marker_symbol},
                    $vector->{design_id},
                    $vector->{design_well}->as_string,
                    $vector->{well}->as_string,
                    $vector->{well}->created_at->ymd,
                    $vector->{cassette}->name,
                    $vector->{backbone},
                    join( q{,}, @{$vector->{recombinase}} ),
                    ( $vector->{cassette}->promoter ? 'promoter' : 'promoterless' ),
                    ( $vector->{well}->accepted ? 'yes' : 'no' )
                ]
            );
        }
    }    
}

sub collect_final_vectors {
    my ( $current_node, $graph, $attrs ) = @_;

    for my $process ( $graph->input_processes( $current_node ) ) {
        if ( my $backbone = $process->process_backbone ) {
            $attrs->{backbone} = $backbone->backbone;
        }
        if ( my $cassette = $process->process_cassette ) {
            $attrs->{cassette} = $cassette->cassette;
        }
        if ( my @recombinase = $process->process_recombinases ) {
            push @{ $attrs->{recombinase} }, map { $_->recombinase_id } sort { $a->rank <=> $b->rank } @recombinase;
        }
    }    

    my @final_vectors;
    
    if ( $current_node->plate->type_id eq 'FINAL' ) {
        push @final_vectors, { %{$attrs}, well => $current_node };
    }

    for my $child_well ( $graph->output_wells( $current_node ) ) {
        my %attrs = ( %{$attrs}, recombinase => [@{$attrs->{recombinase}}] );
        push @final_vectors, collect_final_vectors( $child_well, $graph, \%attrs );
    }

    return @final_vectors;    
}

    
    
