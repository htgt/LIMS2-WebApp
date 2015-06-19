package LIMS2::Report::EPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::EPPlate::VERSION = '0.325';
}
## use critic


use Moose;
use List::MoreUtils qw( apply );
use namespace::autoclean;
use Log::Log4perl qw( :easy );

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );
with qw( LIMS2::ReportGenerator::ColonyCounts );

override plate_types => sub {
    return [ 'EP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Electroporation Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        'Well ID', $self->base_columns,
        "DNA Well",
        "Cassette", "Cassette Resistance", "Recombinases", "Cell Line",
        $self->colony_count_column_names,
        "Number Picked", "Number Accepted", "Number XEPs", 'Report?'
    ]
};

override iterator => sub {
    my $self = shift;

    # prefetch child well data
    my $child_wells_rs = $self->model->schema->resultset( 'PlateChildWells' )->search(
        {}, { bind => [ $self->plate->id ] } );
    my $child_wells = $child_wells_rs->child_well_by_type();

    my $pick_child_wells = pick_child_well_counts( $child_wells );
    my $xep_child_wells = xep_child_well_counts( $child_wells );

    # use custom resultset to gather data for plate report speedily
    # avoid using process graph when adding new data or all speed improvements
    # will be nullified, e.g calling $well->design
    my $rs = $self->model->schema->resultset( 'PlateReport' )->search(
        {},
        {
            bind => [ $self->plate->id ],
        }
    );

    my @wells_data = @{ $rs->consolidate( $self->plate_id,
            [ 'well_qc_sequencing_result', 'well_colony_counts' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};
        my $well_id = $well_data->{well_id};
        my $dna_well_name = $well_data->{well_ancestors}{DNA}{well_name};
        my $ep_pick_child_count = exists $pick_child_wells->{$well_id}
            ? $pick_child_wells->{$well_id}{picked} : 0;
        my $ep_pick_accepted_child_count = exists $pick_child_wells->{$well_id}
                ? $pick_child_wells->{$well_id}{accepted} : 0;
        my $xep_child_count = exists $xep_child_wells->{ $well_id } ? $xep_child_wells->{ $well_id } : 0;

        my @data = (
            $well_data->{well_id},
            $self->base_data_quick( $well_data ),
            $dna_well_name,
            $well_data->{cassette},
            $well_data->{cassette_resistance},
            $well_data->{recombinases},
            $well_data->{cell_line},
            $self->colony_counts( $well ),
            $ep_pick_child_count,
            $ep_pick_accepted_child_count,
            $xep_child_count,
            $well_data->{to_report},
        );

        $well_data = shift @wells_data;
        return \@data;
    };

};

=head2 pick_child_well_counts

Return counts of EP_PICK child wells, and how many of them are accepted

=cut
sub pick_child_well_counts {
    my ( $child_wells ) = @_;

    my %pick_child_wells;
    for my $well_id ( keys %{ $child_wells } ) {
        if ( exists $child_wells->{ $well_id }{EP_PICK} ) {
            my $counts = $child_wells->{ $well_id }{EP_PICK};
            $pick_child_wells{ $well_id }{picked} = $counts->{count};
            $pick_child_wells{ $well_id }{accepted} = $counts->{accepted} || 0;
        }
    }

    return \%pick_child_wells;
}

=head2 xep_child_well_counts

Return counts of XEP child wells
NOTE: not sure XEP plates are direct descendants of EP's anymore,
so this may need to be re-worked

=cut
sub xep_child_well_counts {
    my ( $child_wells ) = @_;

    my %xep_child_wells;
    for my $well_id ( keys %{ $child_wells } ) {
        if ( exists $child_wells->{ $well_id }{XEP} ) {
            $xep_child_wells{ $well_id } = $child_wells->{ $well_id }{XEP}{count};
        }
    }

    return \%xep_child_wells;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
