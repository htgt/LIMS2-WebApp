package LIMS2::Report::SEPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SEPPlate::VERSION = '0.445';
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

    return [ $self->base_columns, 'First DNA Well', 'Second DNA Well', 'Number Picked', 'Number Accepted' ];
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

        my $second_dna = $well->second_dna;

        return [
            $self->base_data( $well ),
            $well->first_dna->as_string,
            $well->second_dna->as_string,
            $self->pick_counts( $well, 'SEP_PICK' )
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
