package LIMS2::Report::PIQPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::PIQPlate::VERSION = '0.079';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'PIQ' ];
};

override _build_name => sub {
    my $self = shift;

    return 'PIQ Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    # acs - 20_05_13 - redmine 10545 - add cassette resistance
    my @columns = (
        $self->base_columns,
        'Electroporation Pick Well',
        'Freezer Well',
    );

    return \@columns;
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

        return [
            $self->base_data( $well ),
            $well->first_ep_pick->as_string,
            $well->freezer_instance->as_string,
        ];
    };
};

__PACKAGE__->meta->make_immutable;

1;

__END__
