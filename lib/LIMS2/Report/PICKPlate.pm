package LIMS2::Report::PICKPlate;

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

    ## PICK plate wells are descendants of 1 parent EP_PIPELINE_II plate well
    my $parent_plates = $self->plate->parent_names();
    my $parent_info = $parent_plates->[0];

    my $data;
    my $species = $self->plate->species_id;
    if ($parent_info->{type_id} eq 'EP_PIPELINE_II') {
        $data = retrieve_data($self->model, $self->plate, $species);
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

    ## Pipeline II PICK plate columns are different than pipeline I PICK

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

__PACKAGE__->meta->make_immutable;

1;

__END__

