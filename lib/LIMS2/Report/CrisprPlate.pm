package LIMS2::Report::CrisprPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprPlate::VERSION = '0.391';
}
## use critic


use Moose;
use namespace::autoclean;
use List::MoreUtils qw(uniq);
use Try::Tiny;
use Log::Log4perl qw(:easy);

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'CRISPR' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Plate ' . $self->plate_name;
};

override _build_columns => sub {
    return [
        "Well Name",
        "Design ID", "Design Type", "Gene ID", "Gene Symbol", "Gene Sponsors",
        "Crispr ID","WGE Crispr ID","Seq","Type","Chromosome", "Start", "End", "Strand", "Assembly",
        "Created By","Created At",
    ];
};

override iterator => sub {
    my $self = shift;

    my @wells = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'process_output_wells'
            ],
            order_by => { -asc => 'me.name' }
        }
    )->all;

    return Iterator::Simple::iter sub {
        my $well = shift @wells
            or return;

        my ( $crispr_data, $locus_data );
        my $process_crispr = $well->process_output_wells->first->process->process_crispr;
        if ( $process_crispr ) {
            $crispr_data = $process_crispr->crispr->as_hash;
            $locus_data = $crispr_data->{locus} if $crispr_data->{locus};
        }

        return [
            $well->name,
            $self->crispr_design_and_gene_cols( $process_crispr->crispr ),
            $crispr_data ? $crispr_data->{id}        : '-',
            $crispr_data ? $crispr_data->{wge_crispr_id} : '-',
            $crispr_data ? $crispr_data->{seq}       : '-',
            $crispr_data ? $crispr_data->{type}      : '-',
            $locus_data  ? $locus_data->{chr_name}   : '-',
            $locus_data  ? $locus_data->{chr_start}  : '-',
            $locus_data  ? $locus_data->{chr_end}    : '-',
            $locus_data  ? $locus_data->{chr_strand} : '-',
            $locus_data  ? $locus_data->{assembly}   : '-',
            $well->created_by->name,
            $well->created_at->ymd,
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
