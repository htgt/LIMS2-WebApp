package LIMS2::Report::PIQPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::PIQPlate::VERSION = '0.504';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'PIQ','CGAP_QC','MS_QC' ];
};

override _build_name => sub {
    my $self = shift;

    return 'PIQ Plate ' . $self->plate_name;
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
            [ 'well_qc_sequencing_result', 'well_lab_number' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};
        my $ep_pick_well_name = $well_data->{well_ancestors}{EP_PICK}{well_name};
        my $fp_well_name = $well_data->{well_ancestors}{FP}{well_name};
        my $well_lab_number = $well->well_lab_number;

        my @data = (
            $self->base_data_quick( $well_data ),
            $ep_pick_well_name,
            $fp_well_name,
            ( $well->well_lab_number ? $well->well_lab_number->lab_number : '' ),
            ( $well->barcode || '' ),
        );

        $well_data = shift @wells_data;
        return \@data;
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
