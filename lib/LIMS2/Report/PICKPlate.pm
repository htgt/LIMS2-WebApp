package LIMS2::Report::PICKPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::PICKPlate::VERSION = '0.094';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'EP_PICK', 'XEP_PICK' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Pick Plate ' . $self->plate_name;
};

# Basic columns, will need to add more as these plate reports start
# getting used.
# Probaby need to add:
# well primer bands
# child wells
# parent well
# qc results
override _build_columns => sub {
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        $self->base_columns,
        "Cassette", "Cassette Resistance", "Recombinases", "Cell Line",
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

        my $process_cell_line = $well->ancestors->find_process( $well, 'process_cell_line' );
        my $cell_line = $process_cell_line ? $process_cell_line->cell_line->name : '';

        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $self->base_data( $well ),
            $well->cassette->name,
            $well->cassette->resistance,
            join( q{/}, @{ $well->recombinases } ),
            $cell_line,
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
