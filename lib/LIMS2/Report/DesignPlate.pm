package LIMS2::Report::DesignPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::DesignPlate::VERSION = '0.435';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'DESIGN' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Design Plate ' . $self->plate_name;
};

override _build_columns => sub {
    return [
        grep { !/Genbank File/ } shift->base_columns,
        "PCR U", "PCR D", "PCR G", "Rec U", "Rec D", "Rec G", "Rec NS", "Rec Result",
    ];
};

override iterator => sub {
    my $self = shift;

    # use custom resultset to gather data for plate report speedily
    # avoid using process graph when adding new data or all speed improvements
    # will be nullified, e.g calling $well->design
    my $rs = $self->model->schema->resultset( 'PlateReport' )->search(
        {},
        {
            prefetch => 'well',
            bind => [ $self->plate->id ],
        }
    );

    my @wells_data = @{ $rs->consolidate( $self->plate_id, [ 'well_recombineering_results' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};
        my %recombineering_results = map { $_->result_type_id => $_->result } $well->well_recombineering_results;

        my @data = (
            $self->base_data_quick( $well_data, { no_eng_seq_link => 1 } ),
            @recombineering_results{ qw( pcr_u pcr_d pcr_g rec_u rec_d rec_g rec_ns rec_result ) },
        );
        $well_data = shift @wells_data;

        return \@data;
    };

};

__PACKAGE__->meta->make_immutable;

1;

__END__
