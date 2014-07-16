package LIMS2::Report::PostIntermediateVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::PostIntermediateVectorPlate::VERSION = '0.218';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'POSTINT' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Post-intermediate Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        $self->base_columns,
        "Cassette", "Cassette Resistance", "Backbone", "Recombinases",
        "Intermedate Well", "Intermediate QC Test Result", "Intermediate Valid Primers", "Intermediate Mixed Reads?", "Intermediate Sequencing QC Pass?",
        "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?",
    ];
};

override iterator => sub {
    my $self = shift;

    my $plate = $self->model->retrieve_plate( { name => $self->plate_name, type_id => 'INT' } );

    my $wells_rs = $plate->search_related(
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
            join( q{/}, @{ $well->recombinases } ),
            $self->ancestor_cols( $well, 'INT' ),
            $self->qc_result_cols( $well )
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
