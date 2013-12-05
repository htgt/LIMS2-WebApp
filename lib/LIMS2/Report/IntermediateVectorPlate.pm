package LIMS2::Report::IntermediateVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::IntermediateVectorPlate::VERSION = '0.134';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'INT' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Intermediate Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        $self->base_columns,
        "Cassette", "Cassette Resistance", "Backbone", "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?"
    ];
};

override iterator => sub {
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

        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $self->base_data( $well ),
            $well->cassette->name,
            $well->cassette->resistance,
            $well->backbone->name,
            $self->qc_result_cols( $well ),
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
