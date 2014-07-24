package LIMS2::Report::CrisprEPDetail;

use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq );
use Try::Tiny;
use Smart::Comments;

extends qw( LIMS2::ReportGenerator );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has '+param_names' => (
    default => sub { [ 'species' ] }
);

override _build_name => sub {
    my $self = shift;

    return 'Crispr Electroporation Detail';

};

override _build_columns => sub {
    my $self = shift;

    return [
        'Gene ID',
        'Gene Symbol',
        'EP Well',
        'Assembly Well',
        'Vector',
        'Vector DNA',
        'Left CRISPR Vector',
        'Left CRISPR DNA',
        'Right CRISPR Vector',
        'Right CRISPR DNA',
        'EPD Count',
        'EPD List',
        'Accepted EPD Count',
        'Accepted EPD List',
    ];
};

override iterator => sub {
    my ( $self ) = @_;

    return Iterator::Simple::iter( $self->build_ep_detail() );

};

## no critic(ProhibitExcessComplexity,ProhibitDeepNests)
sub build_ep_detail {
    my ( $self ) = @_;

    my $species = $self->species;
    my @data;

    my @crispr_ep_plates = $self->model->schema->resultset('Plate')->search({
        type_id => 'CRISPR_EP',
        species_id => $species,
    });

my $well_count = 0;
    # This is the actual summaries table rows
    foreach my $crispr_ep_plate (@crispr_ep_plates) {
        foreach my $crispr_ep_well ($crispr_ep_plate->wells->all){
$well_count++;
            my $wells = {};
            my $wells_test = {};
            $wells->{'crispr_ep'} = $crispr_ep_well;

            my $design = $wells->{'crispr_ep'}->design;
            my $design_id = $design->id;

            my @gene_ids = uniq map { $_->gene_id } $design->genes;
            my @gene_symbols;
            try {
                @gene_symbols  = uniq map {
                    $self->model->find_gene( { species => $species, search_term => $_ } )->{gene_symbol}
                } @gene_ids;
            };
            my $gene_id = join( q{/}, @gene_ids );
            my $gene_symbol = join( q{/}, @gene_symbols );

            foreach my $ep_process ($crispr_ep_well->parent_processes){
                foreach my $input ($ep_process->input_wells){
                    $wells->{'assembly'} = $input;
                }
            }

            foreach my $assembly_process ($wells->{'assembly'}->parent_processes){
                foreach my $dna_well ($assembly_process->input_wells){

                    foreach my $dna_process ($dna_well->parent_processes){
                        foreach my $vector_well ($dna_process->input_wells){
                            if ($vector_well->plate->type_id eq 'FINAL_PICK') {
                                $wells->{'vector'} = $vector_well;
                                $wells->{'vector_dna'} = $dna_well;
                            } else {
                                if ($vector_well->crispr->pam_right) {
                                    $wells->{'r_vector'} = $vector_well;
                                    $wells->{'r_dna'} = $dna_well;
                                } else {
                                    $wells->{'l_vector'} = $vector_well;
                                    $wells->{'l_dna'} = $dna_well;
                                }
                            }
                        }
                    }
                }
            }

            my $ep_pick_list;
            my $ep_pick_pass_list;
            my $ep_pick_count = 0;
            my $ep_pick_pass_count = 0;

            foreach my $process ($crispr_ep_well->child_processes){
                my $proc_name = $process->id;
                foreach my $output ($process->output_wells){
                    $ep_pick_count++;
                    my $plate_name = $output->plate->name;

                    my $well_name = $output->name;
                    my $specification = $plate_name . '[' . $well_name . ']';
                    $ep_pick_list = !$ep_pick_list ? $specification : join q{ }, ( $ep_pick_list, $specification );

                    if ( $output->is_accepted ) {
                        $ep_pick_pass_count++;
                        $ep_pick_pass_list = !$ep_pick_pass_list ? $specification : join q{ }, ( $ep_pick_pass_list, $specification );
                    }
                }
            }

            push @data, [
                $gene_id,
                $gene_symbol,
                $wells->{'crispr_ep'}->plate->name . "_" . $wells->{'crispr_ep'}->name,
                $wells->{'assembly'}->plate->name . "_" . $wells->{'assembly'}->name,
                $wells->{'vector'}->plate->name . "_" . $wells->{'vector'}->name,
                $wells->{'vector_dna'}->plate->name . "_" . $wells->{'vector_dna'}->name,
                $wells->{'l_vector'} ? $wells->{'l_vector'}->plate->name .'_'. $wells->{'l_vector'}->name : '',
                $wells->{'l_dna'} ? $wells->{'l_dna'}->plate->name .'_'. $wells->{'l_dna'}->name : '',
                $wells->{'r_vector'} ? $wells->{'r_vector'}->plate->name .'_'. $wells->{'r_vector'}->name : '',
                $wells->{'r_dna'} ? $wells->{'r_dna'}->plate->name .'_'. $wells->{'r_dna'}->name : '',
                $ep_pick_count,
                $ep_pick_list,
                $ep_pick_pass_count,
                $ep_pick_pass_list,
            ];
        }
    }
### $well_count
    return \@data;

}
## use critic

__PACKAGE__->meta->make_immutable;

1;

__END__