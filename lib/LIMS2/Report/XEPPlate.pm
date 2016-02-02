package LIMS2::Report::XEPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::XEPPlate::VERSION = '0.368';
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

        my $parent_wells_string = join( ', ',
            map { $_->{plate_name} . '[' . $_->{well_name} . ']' }
                @{ $well_data->{parent_wells} } );

        my @data = (
            $self->base_data_quick( $well_data ),
            $parent_wells_string,
        );

        $well_data = shift @wells_data;
        return \@data;
    };
};


__PACKAGE__->meta->make_immutable;

1;

__END__
