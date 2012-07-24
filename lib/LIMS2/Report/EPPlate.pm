package LIMS2::Report::EPPlate;

use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

# XXX If it turns out EP and XEP plates don't have the same data
# stored against them (that is, colony counts) then XEP should be
# removed from here and a new report implemented
override plate_types => sub {
    return [ 'EP', 'XEP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Electroporation Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
        "Cassette", "Recombinases", "Cell Line",
        map { s/_/ /g; s/\b([a-z])/uc($1)/ge; $_ } $self->colony_count_types
    ];
};

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

    [ map { $_->id }
          $self->model->schema->resultset('ColonyCountType')->search( {}, { order_by => { -asc => 'id' } } )
      ];
}

override iterator => sub {
    my $self = shift;

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override', 'well_colony_counts'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;

        my $process_cell_line = $well->ancestors->find_process( $well, 'process_cell_line' );
        my $cell_line = $process_cell_line ? $process_cell_line->cell_line : '';
        my %colony_counts = map { $_->colony_count_type_id => $_->colony_count } $well->well_colony_counts;
        
        return [
            $self->base_data( $well ),
            $well->cassette->name,
            join( q{/}, @{ $well->recombinases } ),
            $cell_line,
            @colony_counts{ $self->colony_count_types }
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
