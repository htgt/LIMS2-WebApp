package LIMS2::Report::CrisprPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprPlate::VERSION = '0.167';
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

        my $gene_symbol = crispr_marker_symbols($self->model, $process_crispr->crispr);

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

sub crispr_marker_symbols{
    my ($model, $crispr) = @_;

    my %symbols;
    foreach my $crispr_design ($crispr->crispr_designs->all){
        my $design = $crispr_design->design;
        _symbols_from_design($model, $design, \%symbols);
    }

    foreach my $pair ($crispr->crispr_pairs_left_crisprs->all, $crispr->crispr_pairs_right_crisprs->all){
        foreach my $pair_crispr_design ($pair->crispr_designs->all){
            my $pair_design = $pair_crispr_design->design;
            _symbols_from_design($model, $pair_design, \%symbols);
        }
    }

    return join ", ", keys %symbols;
}

sub _symbols_from_design{
    my ($model, $design, $symbols) = @_;

    my $design_params = $design->design_parameters;
    my $json = JSON->new;
    my $params;
    try {
      $params = $json->decode( $design_params )
    } catch {
      DEBUG "Could not parse design_parameters json for design ".$design->id." Error: $_";
    };

    return unless $params;

    my $gene;
    try{
      $gene = $model->retrieve_gene({
        species     => $design->species_id,
        search_term => $params->{target_genes}->[0],
      });
    } catch {
        DEBUG "Could not retrieve gene for ".$params->{target_genes}->[0]." Error: $_";
    };

    return unless $gene;

    $symbols->{ $gene->{gene_symbol} } = 1;
    DEBUG "Found symbol ".$gene->{gene_symbol};
    return;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
