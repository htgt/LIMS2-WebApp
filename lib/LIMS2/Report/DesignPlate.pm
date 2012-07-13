package LIMS2::Report::DesignPlate;

use Moose;
use namespace::autoclean;

with 'LIMS2::Role::PlateReportGenerator';

sub _build_name {
    my $self = shift;

    return 'Design Plate ' . $self->plate_name;
}

sub _build_columns {
    return [
        $self->base_columns,
        "PCR U", "PCR D", "PCR G", "Rec U", "Rec D", "Rec G", "Rec NS", "Rec Result",
    ];
}

sub iterator {
    my $self = shift;

    my $plate = $self->model->retrieve_plate( { name => $self->plate_name, type_id => 'DESIGN' } );    
    
    my $wells_rs = $plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override', 'well_recombineering_results'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;

        my %recombineering_results = map { $_->result_type_id => $_->result } $well->well_recombineering_results;

        return [
            $self->base_data( $well ),
            @recombineering_results{ qw( pcr_u pcr_d pcr_g rec_u rec_d rec_g rec_ns rec_result ) },
        ];
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
