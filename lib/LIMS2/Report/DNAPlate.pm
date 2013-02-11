package LIMS2::Report::DNAPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::DNAPlate::VERSION = '0.048';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'DNA' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Final Vector Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
        "Cassette", "Backbone", "Recombinases",
        "Final Vector Well", "Final Vector QC Test Result", "Final Vector Valid Primers", "Final Vector Mixed Reads?", "Final Vector Sequencing QC Pass?",
        "DNA Quality", "DNA Quality Comment", "DNA Pass?"
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

        my $dna_status = $well->well_dna_status;
        my $dna_quality = $well->well_dna_quality;

        return [
            $self->base_data( $well ),
            $well->cassette->name,
            $well->backbone->name,
            join( q{/}, @{ $well->recombinases } ),
            $self->ancestor_cols( $well, 'FINAL' ),
            ( $dna_quality ? ( $dna_quality->quality, $dna_quality->comment_text ) : ('')x2 ),
            ( $dna_status  ? $self->boolean_str( $dna_status->pass ) : '' )
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
