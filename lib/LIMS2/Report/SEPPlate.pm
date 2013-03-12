package LIMS2::Report::SEPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SEPPlate::VERSION = '0.057';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::DoubleTargeted );

override plate_types => sub {
    return [ 'SEP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Second Electroporation Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [ $self->base_columns, 'Number Picked', 'Number Accepted' ];
};

override iterator => sub {
    my $self = shift;

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;

        return [
            $self->base_data( $well ), $self->pick_counts( $well, 'SEP_PICK' )
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
