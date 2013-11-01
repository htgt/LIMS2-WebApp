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
    # my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        "Well Name",#"Crispr Id","Seq","Type","Chromosome", "Start", "End", "Strand", "Assembly",
        "Created By","Created At",
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

        my ( $crispr_data, $locus_data );
        my $process_crispr = $well->process_output_wells->first->process->process_crispr;
        if ( $process_crispr ) {
            $crispr_data = $process_crispr->crispr->as_hash;
            $locus_data = $crispr_data->{locus} if $crispr_data->{locus};
        }


        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            # $crispr_data ? $crispr_data->{id}        : '-',
            # $crispr_data ? $crispr_data->{seq}       : '-',
            # $crispr_data ? $crispr_data->{type}      : '-',
            # $locus_data  ? $locus_data->{chr_name}   : '-',
            # $locus_data  ? $locus_data->{chr_start}  : '-',
            # $locus_data  ? $locus_data->{chr_end}    : '-',
            # $locus_data  ? $locus_data->{chr_strand} : '-',
            # $locus_data  ? $locus_data->{assembly}   : '-',
            $well->created_by->name,
            $well->created_at->ymd,
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
