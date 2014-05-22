package LIMS2::Report::AssemblyPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::AssemblyPlate::VERSION = '0.197';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'ASSEMBLY' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Assembly Plate ' . $self->plate_name;
};

override _build_columns => sub {
    # my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        'Well Name', 'Design ID', 'Gene ID', 'Gene Symbol', 'Gene Sponsors',
        'Left Crispr Well', 'Left Crispr Designs', 'Right Crispr Well','Right Crispr Designs',
        'Cassette', 'Cassette Resistance', 'Cassette Type', 'Backbone', #'Recombinases',
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

        my $left_designs = '-';
        my $right_designs = '-';

        if($left_crispr){
            $left_designs = join "/", map { $_->id } $left_crispr->crispr->related_designs;
        }

        if($right_crispr){
            $right_designs = join "/", map { $_->id } $right_crispr->crispr->related_designs;
        }
        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            $self->design_and_gene_cols($well),
            $left_crispr ? $left_crispr->plate . '[' . $left_crispr->name . ']' : '-',
            $left_designs,
            $right_crispr ? $right_crispr->plate . '[' . $right_crispr->name . ']' : '-',
            $right_designs,
            $final_vector->cassette->name,
            $final_vector->cassette->resistance,
            ( $final_vector->cassette->promoter ? 'promoter' : 'promoterless' ),
            $final_vector->backbone->name,
            # join( q{/}, @{ $final_vector->recombinases } ),
            $well->created_by->name,
            $well->created_at->ymd,
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__