package LIMS2::Report::CrisprSEPPlate;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::CrisprSEPPlate::VERSION = '0.429';
}
## use critic


use Moose;
use namespace::autoclean;
use TryCatch;

extends qw( LIMS2::ReportGenerator::Plate::DoubleTargeted );
with qw( LIMS2::ReportGenerator::ColonyCounts );

sub BUILD{
    my $self = shift;
    $self->show_cassette_info(0);
    $self->show_recombinase_info(0);
    $self->show_crispr_info(1);
    return;
}

override plate_types => sub {
    return [ 'CRISPR_SEP' ];
};

override _build_name => sub {
    my $self = shift;

    return 'Crispr Second Electroporation Plate ' . $self->plate_name;
};

override _build_columns => sub {
    my $self = shift;

    my @columns = (
        $self->base_columns,
    );

    return \@columns;
};

override iterator => sub {
    my $self = shift;

    $self->prefetch_well_ancestors;
    my @wells = $self->plate->wells;

    return Iterator::Simple::iter sub {
        my $well = shift @wells;
        return unless $well;

        return [
            $self->base_data($well)
        ];
    };
};


__PACKAGE__->meta->make_immutable;

1;

__END__
