package LIMS2::Report::EPPlate;

use Moose;
use List::MoreUtils qw( apply );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );
with qw( LIMS2::ReportGenerator::ColonyCounts );

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
        $self->colony_count_column_names
    ];
};

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

        return [
            $self->base_data( $well ),
            $well->cassette->name,
            join( q{/}, @{ $well->recombinases } ),
            $cell_line,
            $self->colony_counts( $well )
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
