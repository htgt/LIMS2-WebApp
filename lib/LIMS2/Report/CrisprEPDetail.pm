package LIMS2::Report::CrisprEPDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprEPDetail::VERSION = '0.309';
}
## use critic


use warnings;
use strict;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
use List::MoreUtils qw( uniq );
use Try::Tiny;
use feature "switch";

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
        'Design ID',
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
        'Frameshift Clones Count',
        'Frameshift Clones List'
    ];
};

override iterator => sub {
    my ( $self ) = @_;

    return Iterator::Simple::iter( $self->build_ep_detail() );

};

## no critic(ProhibitDeepNests)
sub build_ep_detail {
    my ( $self ) = @_;

    my $species = $self->species;
    my @data;

    # get all crispr_ep plates
    my @crispr_ep_plates = $self->model->schema->resultset('Plate')->search({
        type_id => 'CRISPR_EP',
        species_id => $species,
    });

    # for every crispr_ep well
    foreach my $crispr_ep_plate (@crispr_ep_plates) {
        foreach my $crispr_ep_well ($crispr_ep_plate->wells->all){

            # $wells will store the wells to report
            my $wells = {};
            $wells->{'crispr_ep'} = $crispr_ep_well;

            # get the design and gene
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

            # get assembly well
            my @ep_process = $crispr_ep_well->parent_processes;
            my @assembly = $ep_process[0]->input_wells;
            $wells->{'assembly'} = $assembly[0];

            # get dna and vector wells
            my @assembly_process = $wells->{'assembly'}->parent_processes;
            foreach my $dna_well ($assembly_process[0]->input_wells){
                my @dna_process = $dna_well->parent_processes;
                my @vector = $dna_process[0]->input_wells;
                my $vector_well = shift @vector;
                my $vector_well_type = $vector_well->plate->type_id;
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

            # get EPD wells
            my ($ep_pick_list, $ep_pick_pass_list, $fs_list);
            my ($ep_pick_count, $ep_pick_pass_count) = (0, 0);
            my $fs_count = 0;
            my $if_count = 0;
            my $wt_count = 0;
            my $ms_count = 0;

            foreach my $process ($crispr_ep_well->child_processes){
                foreach my $output ($process->output_wells){
                    $ep_pick_count++;
                    my $plate_name = $output->plate->name;
                    my $well_name = $output->name;
                    my $specification = $plate_name . '[' . $well_name . ']';
                    $ep_pick_list = !$ep_pick_list ? $specification : join q{ }, ( $ep_pick_list, $specification );

                    if ( $output->is_accepted ) {
                        $ep_pick_pass_count++;
                        $ep_pick_pass_list = !$ep_pick_pass_list ? $specification : join q{ }, ( $ep_pick_pass_list, $specification );

                        try {
                            my @damage = $self->model->schema->resultset('CrisprEsQcWell')->search({
                                well_id => $output->id,
                                # accepted => 1,
                                'crispr_es_qc_run.validated' => 1,
                            },{
                                join    => 'crispr_es_qc_run',
                            } );
                            foreach my $damage (@damage) {
                                for ($damage->crispr_damage_type_id) {
                                    when ('frameshift') {
                                        $fs_count++;
                                        $fs_list = !$fs_list ? $specification : join q{ }, ( $fs_list, $specification );
                                    }
                                    when ('in-frame')   { $if_count++ }
                                    when ('wild_type')  { $wt_count++ }
                                    when ('mosaic')     { $ms_count++ }
                                    # default { DEBUG "No damage set for well: " . $ep_pick->ep_pick_well_id }
                                }
                            }
                        };

                    }
                }
            }

            # a row is complete
            push @data, [
                $gene_id,
                $gene_symbol,
                $design_id,
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
                $fs_count,
                $fs_list,
            ];
        }
    }

    return \@data;

}
## use critic

__PACKAGE__->meta->make_immutable;

1;

__END__