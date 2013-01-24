package LIMS2::Report::FinalVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::FinalVectorPlate::VERSION = '0.043';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'FINAL' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Final Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
        "Cassette", "Cassette Type", "Backbone", "Recombinases",
        "Intermedate Well", "Intermediate QC Test Result", "Intermediate Valid Primers", "Intermediate Mixed Reads?", "Intermediate Sequencing QC Pass?",
        "Post-intermedate Well", "Post-intermediate QC Test Result", "Post-intermediate Valid Primers", "Post-intermediate Mixed Reads?", "Post-intermediate Sequencing QC Pass?",
        "QC Test Result", "Valid Primers", "Mixed Reads?", "Sequencing QC Pass?"
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

        return [
            $self->base_data( $well ),
            $well->cassette->name,
            ( $well->cassette->promoter ? 'promoter' : 'promoterless' ),
            $well->backbone->name,
            join( q{/}, @{ $well->recombinases } ),
            $self->ancestor_cols( $well, 'INT' ),
            $self->ancestor_cols( $well, 'POSTINT' ),
            $self->qc_result_cols( $well )
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
