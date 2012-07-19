package LIMS2::Report::EPPlate;

use Moose;
use namespace::autoclean;

with 'LIMS2::Role::PlateReportGenerator';

sub plate_type {
    return 'EP';
}

sub _build_name {
    my $self = shift;

    return 'Electroporation Plate ' . $self->plate_name;
}

sub _build_columns {
    my $self = shift;

    return [
        $self->base_columns,
        "Cassette", "Backbone", "Recombinases","Cell Line"
    ];
}

sub iterator {
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

        my $process_electroporation = $well->ancestors->find_process( $well, 'process_electroporation' );
        my $cell_line = $process_electroporation ? $process_electroporation->cell_line : '';

        return [
            $self->base_data( $well ),
            $well->cassette->name,
            $well->backbone->name,
            join( q{/}, @{ $well->recombinases } ),
            $cell_line,
        ];
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
