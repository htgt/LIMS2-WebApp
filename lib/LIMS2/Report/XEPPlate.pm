package LIMS2::Report::XEPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::XEPPlate::VERSION = '0.215';
}
## use critic


use Moose;
use List::MoreUtils qw( apply );
use namespace::autoclean;
use Log::Log4perl qw( :easy );

extends qw( LIMS2::ReportGenerator::Plate::SimpleColumns );

override plate_types => sub {
    return [ 'XEP' ];
};



override _build_name => sub {
    my $self = shift;

    return 'XEP Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    my @columns = (
        $self->base_columns,
       'Parent well list',
    );

    return \@columns;
};

override iterator => sub {
    my $self = shift;

    my $wells_rs = $self->plate->search_related(
        wells => {},
        {
            prefetch => [
                'well_accepted_override', 'well_colony_counts'
            ],
            order_by => { -asc => 'me.name' }
        }
    );

    return Iterator::Simple::iter sub {
        my $well = $wells_rs->next
            or return;

        return [
            $self->base_data( $well ),
            $well->get_input_wells_as_string,
        ];
    };
};


__PACKAGE__->meta->make_immutable;

1;

__END__
