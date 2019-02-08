package LIMS2::Report::FPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::FPPlate::VERSION = '0.525';
}
## use critic


use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

use LIMS2::Model::Util::PipelineIIPlates qw( retrieve_data );

has pipelineII => (
    is         => 'ro',
    lazy_build => 1,
    isa        => 'HashRef',
);

sub _build_pipelineII {
    my ($self) = @_;

    my $data;

    ## find the grandparent of FP plate
    my $fp_parent = $self->plate->parent_names();
    my $fp_info = $fp_parent->[0];

    my $pick_parent_rs = $self->model->schema->resultset('Plate')->find({ name => $fp_info->{name} });
    my $pick_parent = $pick_parent_rs->parent_names();
    my $pick_info = $pick_parent->[0];

    my $species = $self->plate->species_id;
    if ($pick_info->{type_id} eq 'EP_PIPELINE_II') {
        $data = retrieve_data($self->model, $pick_parent_rs, $species);
    }

    return $data;
}

override plate_types => sub {
    return [ 'FP' ];
};

override _build_name => sub {
    my $self = shift;

    if (defined $self->pipelineII) {
        return 'FP Plate ' . $self->plate_name . ' ( Pipeline II )';
    } else {
        return 'FP Plate ' . $self->plate_name . ' ( Pipeline I )';
    }

};

override _build_columns => sub {
    my $self = shift;

    ## Pipeline I and II columns differ

    if (defined $self->pipelineII) {
        return [
            "Well Name", "Experiment ID", "Trivial Name", "Clone ID", "Design ID", "Design Type", "Gene ID", "Gene Symbol", "Cell Line", "Gene Sponsors", "Created At", "Created By", "Accepted", "Barcode"
        ];
    } else {
        return [
            $self->base_columns,
            'Barcode',
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
                $self->pipelineII->{$well_data->name}->{exp_id},
                $self->pipelineII->{$well_data->name}->{exp_trivial},
                $self->plate_name . '_' . $well_data->well_name,
                $self->pipelineII->{$well_data->name}->{design_id},
                $self->pipelineII->{$well_data->name}->{design_type},
                $self->pipelineII->{$well_data->name}->{gene_id},
                $self->pipelineII->{$well_data->name}->{gene_name},
                $self->pipelineII->{$well_data->name}->{cell_line},
                $self->pipelineII->{$well_data->name}->{sponsor_id},
                $well_data->created_at,
                $well_data->created_by->name,
                $well_data->accepted ? 'yes' : 'no',
                $well_data->barcode || ''
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

        my @wells_data = @{ $rs->consolidate( $self->plate_id ) };
        @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

        my $well_data = shift @wells_data;

        return Iterator::Simple::iter sub {
            return unless $well_data;

            my $well = $well_data->{well};

            my @data = (
                $self->base_data_quick( $well_data ),
                ( $well->barcode || '' ),
            );

            $well_data = shift @wells_data;
            return \@data;
        };
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__

