package LIMS2::Report::SEPPICKPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SEPPICKPlate::VERSION = '0.208';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::DoubleTargeted );

override plate_types => sub {
    return [ 'SEP_PICK' ];
};

override _build_name => sub {
    my $self = shift;

    return 'SEP Pick Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
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


        return [
            $self->base_data( $well ),
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
