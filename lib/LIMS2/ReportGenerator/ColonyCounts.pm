package LIMS2::ReportGenerator::ColonyCounts;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::ColonyCounts::VERSION = '0.369';
}
## use critic


use Moose::Role;
use List::MoreUtils qw( apply );
use namespace::autoclean;

requires qw( model );

has colony_count_types => (
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        colony_count_types => 'elements'
    }
);

sub _build_colony_count_types {
    my $self = shift;

    my @types =  map { $_->id } $self->model->schema->resultset('ColonyCountType')->search(
        {},
        { order_by => { -asc => 'id' } }
    );

    return \@types;
}

has colony_count_column_names => (
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        colony_count_column_names => 'elements'
    }
);

sub _build_colony_count_column_names {
    my $self = shift;

    my @names = apply { s/_/ /g; s/\b([a-z])/uc($1)/ge; $_ } $self->colony_count_types;

    return \@names;
};

sub colony_counts {
    my ( $self, $well ) = @_;

    my %colony_counts = map { $_->colony_count_type_id => $_->colony_count }
        $well->well_colony_counts;

    return @colony_counts{ $self->colony_count_types };
}

1;

__END__
