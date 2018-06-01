package LIMS2::Report::PICKPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::PICKPlate::VERSION = '0.505';
}
## use critic


use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

has pipelineII => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_pipelineII {
    my ($self) = @_;

    ## get 1 well ID of this PICK plate
    my @well_rs = $self->model->schema->resultset( 'Well' )->search({ plate_id => $self->plate->id })->all;
    my $well_1 = $well_rs[0];
    my $well_id = $well_1->id;

    ## get parent well ID
    my $ra = $self->model->schema->resultset( 'ProcessOutputWell' )->find({ well_id =>  $well_id }, { columns => [ qw/process_id/ ] });
    my $rb = $self->model->schema->resultset( 'ProcessInputWell' )->find({ process_id =>  $ra->get_column('process_id') }, { columns => [ qw/well_id process_id/ ] });

    my $parent_type = '';
    my $parent_well = $rb->get_column('well_id');

    ## find the type of the parent well
    my $rc = $self->model->schema->resultset( 'Well' )->find({ id => $parent_well }, { columns => [ qw/plate_id/ ] });
    my $rd = $self->model->schema->resultset( 'Plate' )->find({ id => $rc->get_column('plate_id') }, { columns => [ qw/type_id/ ] });

    $parent_type = $rd->get_column('type_id');

    my $data;
    if ($parent_type eq 'EP_PIPELINE_II') {
        $data = $self->get_parent_data($parent_well);
    }

    return $data;
}

override plate_types => sub {
    return [ 'EP_PICK', 'XEP_PICK' ];
};

override _build_name => sub {
    my $self = shift;

    if (defined $self->pipelineII) {
        return 'Pick Plate ' . $self->plate_name . ' ( Pipeline II )';
    } else {
        return 'Pick Plate ' . $self->plate_name . ' ( Pipeline I )';
    }
};

override _build_columns => sub {
    my $self = shift;

    if (defined $self->pipelineII) {
        return [
            "Well Name", "Experiment ID", "Trivial Name", "Clone ID", "Design ID", "Design Type", "Gene ID", "Gene Symbol", "Cell Line", "Gene Sponsors", "Created At", "Created By", "Accepted"
        ];
    } else {
        return [
            $self->base_columns,
            "Experiment ID", "Trivial Name", "Cassette", "Cassette Resistance", "Recombinases", "Cell Line", "Clone ID",
            "QC Pass", "Valid Primers"
        ];
    }
};

override iterator => sub {
    my $self = shift;

    if (defined $self->pipelineII) {
        my @wells = $self->model->schema->resultset( 'Well' )->search({ plate_id => $self->plate->id }, { order_by => 'name' })->all;
        my $well_data = shift @wells;

        return Iterator::Simple::iter sub {
            return unless $well_data;

            my @data = (
                $well_data->name,
                $self->pipelineII->{exp_id},
                $self->pipelineII->{exp_trivial},
                $self->plate_name . '_' . $well_data->well_name,
                $self->pipelineII->{design_id},
                $self->pipelineII->{design_type},
                $self->pipelineII->{gene_id},
                $self->pipelineII->{gene_name},
                $self->pipelineII->{cell_line},
                $self->pipelineII->{sponsor_id},
                $well_data->created_at,
                $self->get_username($well_data->created_by_id),
                $well_data->accepted ? 'yes' : 'no',
            );

            $well_data = shift @wells;#@wells_data;
            return \@data;
        };
    } else {

        # use custom resultset to gather data for plate report speedily
        # avoid using process graph when adding new data or all speed improvements
        # will be nullified, e.g calling $well->design
        my $rs = $self->model->schema->resultset( 'PlateReport' )->search(
            {},
            {
                prefetch => 'well',
                bind => [ $self->plate->id ],
            }
        );

        my @wells_data = @{ $rs->consolidate( $self->plate_id,
                [ 'well_qc_sequencing_result', 'well_primer_bands' ] ) };
        @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

        my $well_data = shift @wells_data;

        return Iterator::Simple::iter sub {
            return unless $well_data;

            my $well = $well_data->{well};

            my @data = (
                $self->base_data_quick( $well_data ),
                '',
                $well_data->{cassette},
                $well_data->{cassette_resistance},
                $well_data->{recombinases},
                $well_data->{cell_line},
                $self->plate_name . '_' . $well_data->{well_name},
                $self->well_qc_sequencing_result_data( $well ),
                $self->well_primer_bands_data( $well ),
            );

            $well_data = shift @wells_data;
            return \@data;
        };
    }
};

sub get_parent_data {
    my ($self, $parent_id) = @_;

    my $parent_process = $self->get_parent_process($parent_id);

    ## design ID
    my $design = $self->get_parent_design($parent_process);

    ## crispr ID
    my $crispr = $self->get_parent_crispr($parent_process);

    ## gene ID et al
    my $gene = $self->get_parent_gene($design->{id}, $crispr);

    ## cell line
    my $cell_line = $self->get_parent_cell_line($parent_process);

    return {design_id => $design->{id}, design_type => $design->{type}, exp_id => $gene->{exp_id}, exp_trivial => $gene->{exp_trivial}, gene_id => $gene->{gene}, gene_name => $gene->{gene_name}, sponsor_id => $gene->{sponsor}, cell_line => $cell_line};
}

sub get_parent_design {
    my ($self, $process_id) = @_;

    my $rs = $self->model->schema->resultset( 'ProcessDesign' )->find({ process_id =>  $process_id }, { columns => [ qw/design_id/ ] });
    my $design_id = $rs->get_column('design_id');

    my $rs1 = $self->model->schema->resultset( 'Design' )->find({ id =>  $design_id }, { columns => [ qw/design_type_id/ ] });
    my $design_type = $rs1->get_column('design_type_id');

    return { id => $design_id, type => $design_type };
}

sub get_parent_crispr {
    my ($self, $process_id) = @_;

    my $res = $self->model->schema->resultset( 'ProcessCrispr' )->find({ process_id =>  $process_id }, { columns => [ qw/crispr_id/ ] });
    my $crispr_id = $res->get_column('crispr_id');

    return $crispr_id;
}

sub get_parent_gene {
    my ($self, $design_id, $crispr_id) = @_;

    my $rs1 = $self->model->schema->resultset( 'Experiment' )->find({ design_id =>  $design_id, crispr_id => $crispr_id }, { columns => [ qw/id gene_id assigned_trivial/ ] });
    my $gene_id = $rs1->get_column('gene_id');
    my $exp_id = $rs1->get_column('id');
    my $exp_trivial = $rs1->trivial_name;
    my $gene_name = $self->get_gene_name($gene_id);

    my $rs2 = $self->model->schema->resultset( 'ProjectExperiment' )->find({ experiment_id =>  $exp_id }, { columns => [ qw/project_id/ ] });
    my $proj_id = $rs2->get_column('project_id');

    my @rs3 = $self->model->schema->resultset( 'ProjectSponsor' )->search({ project_id =>  $proj_id })->all;
    my $sponsor_id = 'All';
    my @sponsor_ids = map { $_->sponsor_id } @rs3;
    foreach (@sponsor_ids) {
        if ($_ ne 'All') { $sponsor_id = $_ };
    }

    return { gene => $gene_id, gene_name => $gene_name, sponsor => $sponsor_id, exp_id => $exp_id, exp_trivial => $exp_trivial };
}

sub get_parent_process {
    my ($self, $well_id) = @_;

    my $res = $self->model->schema->resultset( 'ProcessOutputWell' )->find({ well_id => $well_id }, { columns => [ qw/process_id/ ] });
    my $process_id = $res->get_column('process_id');

    return $process_id;
}

sub get_parent_cell_line {
    my ($self, $process_id) = @_;

    my $res = $self->model->schema->resultset( 'ProcessCellLine' )->find({ process_id =>  $process_id }, { columns => [ qw/cell_line_id/ ] });
    my $cell_line_id = $res->get_column('cell_line_id');
    my $rs_cell_line = $self->model->schema->resultset( 'CellLine' )->find({ id => $cell_line_id }, { columns => [ qw/name/ ] });

    return $rs_cell_line->get_column('name');
}

sub get_username {
    my ($self, $user_id) = @_;

    my $rs = $self->model->schema->resultset( 'User' )->find({ id =>  $user_id }, { columns => [ qw/name/ ] });
    my $name = $rs->get_column('name');

    return $name;
}

sub get_gene_name {
    my ($self, $gene_id) = @_;

    my $db_rec = $self->model->schema->resultset( 'Plate' )->find({ id =>  $self->plate->id }, { columns => [ qw/species_id/ ] });
    my $plate_species = $db_rec->get_column('species_id');

    my $gene_info;
    try {
        $gene_info = $self->model->find_gene( { search_term => $gene_id, species => $plate_species } ) ;
    };

    if ( $gene_info ) {
        return $gene_info->{gene_symbol};
    }

    return $gene_id;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

