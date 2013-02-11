package LIMS2::Report::FPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::FPPlate::VERSION = '0.049';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'FP', 'SFP' ];
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
