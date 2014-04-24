package LIMS2::Report::CrisprVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprVectorPlate::VERSION = '0.185';
}
## use critic


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
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        'Well Name',
        "Design Id", "Gene Id", "Gene Symbol", "Gene Sponsors",
        'Crispr Plate', 'Crispr Well',
        'Backbone',
        'Created By','Created At',
        'Accepted?',
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

        my $crispr_well = $well->parent_crispr;
        my $crispr = $crispr_well->crispr;

        my $backbone = '';
        if ($well->backbone) {
            $backbone = $well->backbone->name;
        }
        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            $self->crispr_design_and_gene_cols($crispr),
            $crispr_well->plate,
            $crispr_well->name,
            $backbone,
            $well->created_by->name,
            $well->created_at->ymd,
            $self->boolean_str( $well->is_accepted ),
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
