package LIMS2::Report::Plates;

use Moose;
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

has plate_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_name {
    shift->plate_type . ' Plate Report';
}

sub _build_columns {
    [ "Type", "Name", "Created By", "Created At", "Description" ]
}

sub iterator {
    my ( $self ) = @_;

    my $rs = $self->model->schema->resultset( 'Plate' )->search(
        { type_id => $self->plate_type },
        { order_by => { -desc => 'created_at' } }
    );

    return Iterator::Simple::iter(
        sub {
            my $r = $rs->next
                or return;
            return [ $r->type_id, $r->name, $r->created_by->name, $r->created_at->iso8601, $r->description ];
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
