package LIMS2::Report::PlateList;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::PlateList::VERSION = '0.440';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use LIMS2::Model::Util qw( sanitize_like_expr );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

has plate_type => (
    is  => 'ro',
    isa => 'Maybe[Str]'
);

has plate_name => (
    is  => 'ro',
    isa => 'Maybe[Str]'
);

has '+param_names' => (
    default => sub { [ 'plate_type', 'plate_name' ] }
);

override _build_name => sub {
    my $self = shift;
    if ( $self->plate_type ) {
        return $self->plate_type . ' Plate List';
    }
    return 'Plate List';
};

override _build_columns => sub {
    return [ "Plate Name", "Plate Type", "Description", "Created By", "Created At" ];
};

override iterator => sub {
    my ($self) = @_;

    my %search_params;

    if ( $self->plate_type and $self->plate_type ne '-' ) {
        $search_params{'me.type_id'} = $self->plate_type;
    }

    if ( $self->plate_name ) {
        $search_params{'me.name'} = { -like => '%' . sanitize_like_expr( $self->plate_name ) . '%' };
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
};

__PACKAGE__->meta->make_immutable;

1;

__END__
