package LIMS2::Report::SFPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SFPPlate::VERSION = '0.454';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::DoubleTargeted );

sub BUILD{
    my $self = shift;
    $self->show_cassette_info(0);
    $self->show_recombinase_info(0);
    $self->show_crispr_info(0);
    return;
}

override plate_types => sub {
    return [ 'SFP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'SFP Plate ' . $self->plate_name;
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

    $self->prefetch_well_ancestors;
    my @wells = $self->plate->wells;

    return Iterator::Simple::iter sub {
        my $well = shift @wells
            or return;

        return [
            $self->base_data( $well ),
            $well->barcode,
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__