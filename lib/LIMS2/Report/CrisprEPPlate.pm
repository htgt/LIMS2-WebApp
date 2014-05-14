package LIMS2::Report::CrisprEPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprEPPlate::VERSION = '0.193';
}
## use critic


use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'CRISPR_EP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Electroporation Plate ' . $self->plate_name;
};

override _build_columns => sub {
    # my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        'Well Name', 'Design ID', 'Gene ID', 'Gene Symbol', 'Gene Sponsors',
        'Cassette', 'Cassette Resistance', 'Cassette Type', 'Backbone', 'Nuclease', 'Cell Line',
        'Left Crispr', 'Right Crispr',
        'Created By','Created At',
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

        my $final_vector = $well->final_vector;
        my ($left_crispr,$right_crispr) = $well->left_and_right_crispr_wells;
        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            $self->design_and_gene_cols($well),
            $final_vector->cassette ? $final_vector->cassette->name       : '-',
            $final_vector->cassette ? $final_vector->cassette->resistance : '-',
            ( $final_vector->cassette->promoter ? 'promoter' : 'promoterless' ),
            $final_vector->backbone ? $final_vector->backbone->name       : '-',
            $well->nuclease         ? $well->nuclease->name               : '-',
            $well->first_cell_line  ? $well->first_cell_line->name        : '-',
            $left_crispr            ? $left_crispr->plate . '[' . $left_crispr->name . ']' : '-',
            $right_crispr           ? $right_crispr->plate . '[' . $right_crispr->name . ']' : '-',
            # join( q{/}, @{ $final_vector->recombinases } ),
            $well->created_by->name,
            $well->created_at->ymd,
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
