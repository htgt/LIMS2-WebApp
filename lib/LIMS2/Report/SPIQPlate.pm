package LIMS2::Report::SPIQPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SPIQPlate::VERSION = '0.525';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::DoubleTargeted );

sub BUILD{
    my $self = shift;
    $self->show_cassette_info(0);
    $self->show_recombinase_info(0);
    return;
}

override plate_types => sub {
    return [ 'S_PIQ' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Second PIQ Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

   my @columns = (
        $self->base_columns,
        'Electroporation Pick Well',
        'Freezer Well',
        'Lab Number',
        'Barcode',
    );

    return \@columns;
};

override iterator => sub {
    my $self = shift;

    $self->prefetch_well_ancestors;
    my @wells = $self->plate->wells;

    return Iterator::Simple::iter sub {
        my $well = shift @wells
            or return;

        my $ep_pick_well_name = $well->second_ep_pick->as_string;
        my $fp_well_name = $well->freezer_instance->as_string;

        return [
            $self->base_data( $well ),
            $ep_pick_well_name,
            $fp_well_name,
            ( $well->well_lab_number ? $well->well_lab_number->lab_number : '' ),
            ( $well->barcode || '' ),
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__