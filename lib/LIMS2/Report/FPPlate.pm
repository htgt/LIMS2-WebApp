package LIMS2::Report::FPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::FPPlate::VERSION = '0.417';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'FP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'FP Plate ' . $self->plate_name;
};

# Basic columns, will need to add more
override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
        'Barcode',
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
};

__PACKAGE__->meta->make_immutable;

1;

__END__
