package LIMS2::Report::FinalPickVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::FinalPickVectorPlate::VERSION = '0.466';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'FINAL_PICK' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Final Pick Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
        $self->accepted_crispr_columns,
        "Cassette", "Cassette Resistance", "Cassette Type", "Backbone", "Recombinases",
        "Intermedate Well", "Intermediate QC Test Result", "Intermediate Valid Primers", "Intermediate Mixed Reads?", "Intermediate Sequencing QC Pass?",
        "Final Well", "Final QC Test Result", "Final Valid Primers", "Final Mixed Reads?", "Final Sequencing QC Pass?",
        "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?"
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

    my @wells_data = @{ $rs->consolidate( $self->plate_id, [ 'well_qc_sequencing_result' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    # Set well_design_ids hash in LIMS2::Report::Plate, see method for details
    $self->set_well_designs( \@wells_data );

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my $well = $well_data->{well};

        my @data = (
            $self->base_data_quick( $well_data ),
            $self->accepted_crispr_data( $well, 'CRISPR_V' ),
            $well_data->{cassette},
            $well_data->{cassette_resistance},
            $well_data->{cassette_promoter},
            $well_data->{backbone},
            $well_data->{recombinases},
            $self->ancestor_cols_quick( $well_data, 'INT' ),
            $self->ancestor_cols_quick( $well_data, 'FINAL' ),
            $self->qc_result_cols( $well ),
        );

        $well_data = shift @wells_data;
        return \@data;
    };

};

__PACKAGE__->meta->make_immutable;

1;

__END__
