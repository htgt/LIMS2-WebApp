package LIMS2::Report::IntermediateVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::IntermediateVectorPlate::VERSION = '0.007';
}
## use critic


use Moose;
use namespace::autoclean;

with 'LIMS2::Role::PlateReportGenerator';

sub plate_type {
    return 'INT';
}

sub _build_name {
    my $self = shift;

    return 'Intermediate Vector Plate ' . $self->plate_name;
}
sub _build_columns {
    my $self = shift;

    return [
        $self->base_columns,
        "Cassette", "Backbone", "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?"
    ];
}

sub iterator {
    my $self = shift;

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override', 'well_qc_sequencing_result'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;

        return [
            $self->base_data( $well ),
            $well->cassette->name,
            $well->backbone->name,
            $self->qc_result_cols( $well ),
        ];
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
