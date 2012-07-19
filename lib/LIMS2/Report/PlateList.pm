package LIMS2::Report::PlateList;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

has plate_type => (
    is  => 'ro',
    isa => 'Maybe[Str]'
);

sub _build_name {
    my $self = shift;
    if ( $self->plate_type ) {
        return $self->plate_type . ' Plate List';
    }
    return 'Plate List';
}

sub _build_columns {
    return [ "Plate Name", "Plate Type", "Description", "Created By", "Created At" ];
}

sub iterator {
    my ($self) = @_;

    my %search_params;

    if ( $self->plate_type and $self->plate_type ne '-' ) {
        $search_params{'me.type_id'} = $self->plate_type;
    }

    my $plate_rs = $self->model->schema->resultset('Plate')->search(
        \%search_params,
        {   order_by => { -desc => 'created_at' },
            prefetch => ['created_by']
        }
    );

    return Iterator::Simple::iter sub {
        my $plate = $plate_rs->next
            or return;
        return [ $plate->name, $plate->type_id, $plate->description, $plate->created_by->name,
            $plate->created_at->ymd ];
    };
}

1;

__END__
