package LIMS2::Report::EPPipelineIIPlate;

use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

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
            cell_number     => $well_name[1],
            trivial_name    => $well_info->{trivial_name},
            experiment_id   => $well_info->{experiment_id},
            design_id       => $well_info->{design_id},
            crispr_id       => $well_info->{crispr_info}->{crispr_id},
            crispr_loc      => $well_info->{crispr_loc},
            crispr_pair_id  => $well_info->{crispr_info}->{crispr_pair_id},
            crispr_group_id => $well_info->{crispr_info}->{crispr_group_id},
            gene_id         => $well_info->{gene_id},
            cell_line       => $well_info->{cell_line},
            protein_type    => $well_info->{protein_type},
            guided_type     => $well_info->{guided_type},
            project_id      => $well_info->{project_id},
            created_by      => $well_info->{created_by}
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

override _build_columns => sub {
    my $self = shift;

    return [
        'Cell Number', 'Experiment', 'Experiment ID', 'Design ID', 'Crispr ID', 'Crispr Location', 'Crispr Pair ID', 'Crispr Group ID', 'Gene ID', 'Cell Line', 'Protein Type', 'Guided Type', 'Project ID', 'Created By'
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
            $well_data->{trivial_name},
            $well_data->{experiment_id},
            $well_data->{design_id},
            $well_data->{crispr_id},
            $well_data->{crispr_loc},
            $well_data->{crispr_pair_id},
            $well_data->{crispr_group_id},
            $well_data->{gene_id},
            $well_data->{cell_line},
            $well_data->{protein_type},
            $well_data->{guided_type},
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

    my $crispr_info;

    my $well_process = $self->get_well_process($well_id);

    my $res = $self->model->schema->resultset( 'ProcessCrispr' )->find({ process_id =>  $well_process }, { columns => [ qw/crispr_id/ ] });
    my $res_pair = $self->model->schema->resultset( 'ProcessCrisprPair' )->find({ process_id =>  $well_process }, { columns => [ qw/crispr_pair_id/ ] });
    my $res_group = $self->model->schema->resultset( 'ProcessCrisprGroup' )->find({ process_id =>  $well_process }, { columns => [ qw/crispr_group_id/ ] });

    if ($res) {
        $crispr_info->{crispr_id} = $res->get_column('crispr_id');
    } elsif ($res_pair) {
        my $crispr_pair_id = $res_pair->get_column('crispr_pair_id');
#        my $rec = $self->model->schema->resultset( 'CrisprPair' )->find({ id =>  $crispr_pair_id }, { columns => [ qw/left_crispr_id right_crispr_id/ ] });
#        my @crisprs = ($rec->get_column('left_crispr_id'), $rec->get_column('right_crispr_id'));
        $crispr_info->{crispr_pair_id} = $crispr_pair_id;# @crisprs;
    } elsif ($res_group) {
        my $crispr_group_id = $res_group->get_column('crispr_group_id');
#        my @rec = $self->model->schema->resultset( 'CrisprGroupCrispr' )->search({ id =>  $crispr_group_id })->all;
#        my @crisprs = map { $_->crispr_id } @rec;
        $crispr_info->{crispr_group_id} = $crispr_group_id;#@crisprs;
    }

    return $crispr_info;
}

sub get_well_cell_line {
    my ($self, $well_id) = @_;

    my $well_process = $self->get_well_process($well_id);

    my $res = $self->model->schema->resultset( 'ProcessCellLine' )->find({ process_id =>  $well_process }, { columns => [ qw/cell_line_id/ ] });
    my $cell_line_id = $res->get_column('cell_line_id');

    return $cell_line_id;
}

sub get_well_protein_type {
    my ($self, $well_id) = @_;

    my $well_process = $self->get_well_process($well_id);

    my $res = $self->model->schema->resultset( 'ProcessNuclease' )->find({ process_id =>  $well_process }, { columns => [ qw/nuclease_id/ ] });
    my $nuclease_id = $res->get_column('nuclease_id');

    return $nuclease_id;
}

sub get_well_guided_type {
    my ($self, $well_id) = @_;

    my $well_process = $self->get_well_process($well_id);

    my $res = $self->model->schema->resultset( 'ProcessGuidedType' )->find({ process_id =>  $well_process }, { columns => [ qw/guided_type_id/ ] });
    my $guided_type_id = $res->get_column('guided_type_id');

    return $guided_type_id;
}

sub get_well_gene {
    my ($self, $design_id, $other_info) = @_;

    $other_info->{design_id} = $design_id;
    my $res = $self->model->schema->resultset( 'Experiment' )->find( $other_info, { columns => [ qw/gene_id/ ] });

    return $res->get_column('gene_id');
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

sub get_well_info {
    my ($self, $well_id) = @_;

    my $info;
    $info->{design_id} = $self->get_well_design($well_id);
    $info->{crispr_info} = $self->get_well_crispr($well_id);
    $info->{gene_id} = $self->get_well_gene($info->{design_id}, $info->{crispr_info});

    ## get created by
    my $db_user_id = $self->model->schema->resultset( 'Well' )->find({ id => $well_id }, { columns => [ qw/created_by_id/ ] });
    my $db_user = $self->model->schema->resultset( 'User' )->find({ id => $db_user_id->get_column('created_by_id') }, { columns => [ qw/name/ ] });

    ## get crispr location in storage
    my @crispr_boxes;
    my $crispr_locs = 'NA';

    if ($info->{crispr_info}->{crispr_id}) {
        my @db_crispr_storage = $self->model->schema->resultset( 'CrisprStorage' )->search({ crispr_id => $info->{crispr_info}->{crispr_id} }, { distinct => 1 })->all;
        for my $rec (@db_crispr_storage) {
            push @crispr_boxes, $rec->get_column('box_name');
        }
    }

    if (scalar @crispr_boxes) { $crispr_locs = join ",", @crispr_boxes; }

    my $exp_search;
    $exp_search->{design_id} = $info->{design_id};
    $exp_search->{crispr_id} = $info->{crispr_info}->{crispr_id};
    $exp_search->{crispr_pair_id} = $info->{crispr_info}->{crispr_pair_id};
    $exp_search->{crispr_group_id} = $info->{crispr_info}->{crispr_group_id};

    ## get well experiment
    my $db_exp = $self->model->schema->resultset( 'Experiment' )->find($exp_search, { columns => [ qw/id gene_id assigned_trivial/ ] });
    $info->{experiment_id} = $db_exp->get_column('id');
    $info->{trivial_name} = $db_exp->trivial_name;

    ## get project experiment
    my @db_proj_exp = $self->model->schema->resultset( 'ProjectExperiment' )->search({ experiment_id => $db_exp->get_column('id') })->all;
    my @projs = map { $_->project_id } @db_proj_exp;

    ## validate project using cell line
    my $cell_line_id = $self->get_well_cell_line($well_id);

    ## get cell line name
    my $db_cell_line = $self->model->schema->resultset( 'CellLine' )->find({ id => $cell_line_id }, { columns => [ qw/name/ ] });

    ## get protein type
    my $protein_type_id = $self->get_well_protein_type($well_id);
    my $db_protein_type = $self->model->schema->resultset( 'Nuclease' )->find({ id => $protein_type_id }, { columns => [ qw/name/ ] });

    ## get guided type
    my $guided_type_id = $self->get_well_guided_type($well_id);
    my $db_guided_type = $self->model->schema->resultset( 'GuidedType' )->find({ id => $guided_type_id }, { columns => [ qw/name/ ] });

    ## prepare report data
    $info->{project_id} = join ",", @projs;
    $info->{cell_line} = $db_cell_line->get_column('name');
    $info->{protein_type} = $db_protein_type->get_column('name');
    $info->{guided_type} = $db_guided_type->get_column('name');
#    $info->{gene_id} = $self->get_gene_name($info->{gene_id});
    $info->{crispr_loc} = $crispr_locs;
    $info->{created_by} = $db_user->get_column('name');

    return $info;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

