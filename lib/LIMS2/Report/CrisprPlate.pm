package LIMS2::Report::CrisprPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprPlate::VERSION = '0.168';
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
        "Well Name","Gene Symbol","Crispr Id","Seq","Type","Chromosome", "Start", "End", "Strand", "Assembly",
        "Created By","Created At",
    ];
};

override iterator => sub {
    my $self = shift;

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'process_output_wells'
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

        my $gene_symbol = $self->crispr_marker_symbols($process_crispr->crispr);

        return [
            $well->name,
            $gene_symbol ? $gene_symbol : '-',
            $crispr_data ? $crispr_data->{id}        : '-',
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
