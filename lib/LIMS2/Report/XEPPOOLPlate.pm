package LIMS2::Report::XEPPOOLPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::XEPPOOLPlate::VERSION = '0.386';
}
## use critic


use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate::SingleTargeted );

override plate_types => sub {
    return [ 'XEP_POOL' ];
};

override _build_name => sub {
    my $self = shift;

    return 'XEP Pool Plate ' . $self->plate_name;
};

# Basic columns, will need to add more
override _build_columns => sub {
    my $self = shift;

    return [
        $self->base_columns,
    ];
};

override iterator => sub {
    my $self = shift;

    # use custom resultset to gather data for plate report speedily
    # avoid using process graph when adding new data or all speed improvements
    # will be nullified, e.g calling $well->design
    my $rs = $self->model->schema->resultset( 'PlateReport' )->search(
        {},
        {
            bind => [ $self->plate->id ],
        }
    );

    my @wells_data = @{ $rs->consolidate( $self->plate_id, [ 'well_qc_sequencing_result' ] ) };
    @wells_data = sort { $a->{well_name} cmp $b->{well_name} } @wells_data;

    my $well_data = shift @wells_data;

    return Iterator::Simple::iter sub {
        return unless $well_data;

        my @data = (
            $self->base_data_quick( $well_data ),
        );

        $well_data = shift @wells_data;
        return \@data;
    };

};

__PACKAGE__->meta->make_immutable;

1;

__END__
