package LIMS2::Report::CrisprEPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprEPPlate::VERSION = '0.148';
}
## use critic


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
        my ($crispr1, $crispr2) = $well->parent_crispr_v;#->parent_crispr;

        my ($right_crispr, $left_crispr);
        if (defined $crispr2) {
            if ($crispr2->crispr->pam_right) {
                $right_crispr = $crispr2->parent_crispr->plate . '[' . $crispr2->parent_crispr->name . ']';
                $left_crispr = $crispr1->parent_crispr->plate . '[' . $crispr1->parent_crispr->name . ']';
            } else {
                $right_crispr = $crispr1->parent_crispr->plate . '[' . $crispr1->parent_crispr->name . ']';
                $left_crispr = $crispr2->parent_crispr->plate . '[' . $crispr2->parent_crispr->name . ']';
            }
        } elsif (defined $crispr1) {
            $right_crispr = '';
            $left_crispr = $crispr1->parent_crispr->plate . '[' . $crispr1->parent_crispr->name . ']';
        }

        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            $final_vector->cassette->name,
            $final_vector->cassette->resistance,
            ( $final_vector->cassette->promoter ? 'promoter' : 'promoterless' ),
            $final_vector->backbone->name,
            $left_crispr,
            $right_crispr,
            # join( q{/}, @{ $final_vector->recombinases } ),
            $well->created_by->name,
            $well->created_at->ymd,
        ];
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
