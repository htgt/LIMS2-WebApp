package LIMS2::Report::CrisprVectorPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprVectorPlate::VERSION = '0.153';
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

    ### $self

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    return [
        'Well Name',
        'Crispr Plate', 'Crispr Well',
        'Backbone',
        'Created By','Created At',
        'Accepted?',
    ];
};

override iterator => sub {
    my $self = shift;

    ### $self


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

        my $crispr = $well->parent_crispr;

        my $backbone = '';
        if ($well->backbone) {
            $backbone = $well->backbone->name;
        }
        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        return [
            $well->name,
            $crispr->plate,
            $crispr->name,
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
