package LIMS2::Report::CrisprVectorPlate;

use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'CRISPR_V' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        $self->base_columns,
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

        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $self->base_data( $well ),
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
