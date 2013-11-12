package LIMS2::Report::CrisprEPPlate;

use Moose;
use namespace::autoclean;

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
        'Well Name',
        'Cassette', 'Cassette Resistance', 'Cassette Type', 'Backbone', #'Recombinases',
        'Crispr Plate', 'Crispr Well',
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
        my $crispr = $well->parent_crispr_v->parent_crispr;

        my ( $crispr_data, $locus_data );
        my $process_crispr = $well->process_output_wells->first->process->process_crispr;
        if ( $process_crispr ) {
            $crispr_data = $process_crispr->crispr->as_hash;
            $locus_data = $crispr_data->{locus} if $crispr_data->{locus};
        }


        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            $final_vector->cassette->name,
            $final_vector->cassette->resistance,
            ( $final_vector->cassette->promoter ? 'promoter' : 'promoterless' ),
            $final_vector->backbone->name,
            $crispr->plate,
            $crispr->name,
            # join( q{/}, @{ $final_vector->recombinases } ),
            $well->created_by->name,
            $well->created_at->ymd,
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
