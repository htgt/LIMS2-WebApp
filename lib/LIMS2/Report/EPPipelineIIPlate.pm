package LIMS2::Report::EPPipelineIIPlate;

use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );
#with qw( LIMS2::ReportGenerator::ColonyCounts );

#has bypass_oligo_assembly => (
#    is         => 'ro',
#    required => 0,
#);

#has orginal_design => (
#    is        =>  'ro',
#    require   => 0,
#);

has wells_data => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_wells_data {
    my ($self) = @_;

    my @wells_data;
    my @well_ids;
    my @rs = $self->model->schema->resultset( 'Well' )->search({ plate_id => $self->plate->id }, { order_by => 'id' })->all;
    foreach my $well (@rs) {
        my @well_name = split "A", $well->name;
        my $well_info = $self->get_well_info($well->id);
        push @well_ids, $well->id;
        my $temp = {
            cell_number   => $well_name[1],
            experiment_id => $well_info->{experiment_id},
            design_id     => $well_info->{design_id},
            crispr_id     => $well_info->{crispr_id},
            crispr_loc    => $well_info->{crispr_loc},
            gene_id       => $well_info->{gene_id},
            cell_line     => $well_info->{cell_line},
            project_id    => $well_info->{project_id},
            created_by    => $well_info->{created_by}
        };
        push @wells_data, $temp;
    }

    return \@wells_data;
}

override plate_types => sub {
    return [ 'EP_PIPELINE_II' ];
};

override _build_name => sub {
    my $self = shift;

    return 'EP Pipeline II Plate ' . $self->plate_name;
};

#override _build_name => sub {
#    my $self = shift;
#};

override _build_columns => sub {
    my $self = shift;

    return [
        'Cell Number', 'Experiment ID', 'Design ID', 'Crispr ID', 'Crispr Location', 'Gene ID', 'Cell Line', 'Project ID', 'Created By'
    ];
};

override iterator => sub {
    my $self = shift;

    my @wells_data = @{ $self->wells_data };

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my @data = (
            $well_data->{cell_number},
            $well_data->{experiment_id},
            $well_data->{design_id},
            $well_data->{crispr_id},
            $well_data->{crispr_loc},
            $well_data->{gene_id},
            $well_data->{cell_line},
            $well_data->{project_id},
            $well_data->{created_by}
        );

        $well_data = shift @wells_data;
        return \@data;
    };
};

sub get_well_process {
    my ($self, $well_id) = @_;

    my $res = $self->model->schema->resultset( 'ProcessOutputWell' )->find({ well_id => $well_id }, { columns => [ qw/process_id/ ] });
    my $process_id = $res->get_column('process_id');

    return $process_id;
}

sub get_well_design {
    my ($self, $well_id) = @_;

    my $well_process = $self->get_well_process($well_id);

    my $res = $self->model->schema->resultset( 'ProcessDesign' )->find({ process_id =>  $well_process }, { columns => [ qw/design_id/ ] });
    my $design_id = $res->get_column('design_id');

    return $design_id;
}

sub get_well_crispr {
    my ($self, $well_id) = @_;

    my $well_process = $self->get_well_process($well_id);

    my $res = $self->model->schema->resultset( 'ProcessCrispr' )->find({ process_id =>  $well_process }, { columns => [ qw/crispr_id/ ] });
    my $crispr_id = $res->get_column('crispr_id');

    return $crispr_id;
}

sub get_well_cell_line {
    my ($self, $well_id) = @_;

    my $well_process = $self->get_well_process($well_id);

    my $res = $self->model->schema->resultset( 'ProcessCellLine' )->find({ process_id =>  $well_process }, { columns => [ qw/cell_line_id/ ] });
    my $cell_line_id = $res->get_column('cell_line_id');

    return $cell_line_id;
}

sub get_well_gene {
    my ($self, $design_id, $crispr_id) = @_;

    my $res = $self->model->schema->resultset( 'Experiment' )->find({ design_id =>  $design_id, crispr_id => $crispr_id }, { columns => [ qw/gene_id/ ] });

    return $res->get_column('gene_id');
}

sub get_gene_name {
    my ($self, $gene_id) = @_;

    my $db_rec = $self->model->schema->resultset( 'Plate' )->find({ id =>  $self->plate->id }, { columns => [ qw/species_id/ ] });
    my $plate_species = $db_rec->get_column('species_id');

    my $gene_info = $self->model->find_gene( { search_term => $gene_id, species => $plate_species } ) ;

    if ( $gene_info ) {
        return $gene_info->{gene_symbol};
    }

    return $gene_id;
}

sub get_well_info {
    my ($self, $well_id) = @_;

    my $info;
    $info->{design_id} = $self->get_well_design($well_id);
    $info->{crispr_id} = $self->get_well_crispr($well_id);
    $info->{gene_id} = $self->get_well_gene($info->{design_id}, $info->{crispr_id});

    ##TODO -

    ## get created by
    my $db_user_id = $self->model->schema->resultset( 'Well' )->find({ id => $well_id }, { columns => [ qw/created_by_id/ ] });
    my $db_user = $self->model->schema->resultset( 'User' )->find({ id => $db_user_id->get_column('created_by_id') }, { columns => [ qw/name/ ] });

    ## get crispr location in storage
    my @db_crispr_storage = $self->model->schema->resultset( 'CrisprStorage' )->search({ crispr_id => $info->{crispr_id} }, { distinct => 1 })->all;
    my @crispr_boxes;
    my $crispr_locs = 'NA';

    for my $rec (@db_crispr_storage) {
        push @crispr_boxes, $rec->get_column('box_name');
    }

    if (scalar @crispr_boxes) { $crispr_locs = join ",", @crispr_boxes; }

    ## get well experiment
    my $db_exp = $self->model->schema->resultset( 'Experiment' )->find($info, { columns => [ qw/id/ ] });
    $info->{experiment_id} = $db_exp->get_column('id');

    ## get project experiment
    my @db_proj_exp = $self->model->schema->resultset( 'ProjectExperiment' )->search({ experiment_id => $db_exp->get_column('id') })->all;
    my @projs = map { $_->project_id } @db_proj_exp;

    ## validate project using cell line
    my $cell_line_id = $self->get_well_cell_line($well_id);
    my $db_proj = $self->model->schema->resultset( 'Project' )->find({ gene_id =>  $info->{gene_id}, cell_line_id => $cell_line_id }, { columns => [ qw/id/ ] });

    ## get cell line name
    my $db_cell_line = $self->model->schema->resultset( 'CellLine' )->find({ id => $cell_line_id }, { columns => [ qw/name/ ] });

    ## prepare report data
    $info->{project_id} = $db_proj->get_column('id');
    $info->{cell_line} = $db_cell_line->get_column('name');
    $info->{gene_id} = $self->get_gene_name($info->{gene_id});
    $info->{crispr_loc} = $crispr_locs;
    $info->{created_by} = $db_user->get_column('name');

    return $info;
}

__PACKAGE__->meta->make_immutable;

1;

__END__


