package LIMS2::Report::PreIntermediateVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::PreIntermediateVectorPlate::VERSION = '0.472';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'PREINT' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Pre-Intermediate Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
        "Browser",
        # "Cassette", "Cassette Resistance",
        "Backbone",
        "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?",
    ];
};

override iterator => sub {
    my $self = shift;

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

    my @wells_data = @{ $rs->consolidate( $self->plate_id, [ 'well_qc_sequencing_result' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};

        my @data = (
            $self->base_data_quick( $well_data ),
            $self->genoverse_button( $well_data ),
            # $well_data->{cassette},
            # $well_data->{cassette_resistance},
            $well_data->{backbone},
            $self->qc_result_cols( $well ),
        );

        $well_data = shift @wells_data;
        return \@data;
    };

};

__PACKAGE__->meta->make_immutable;

1;

__END__
