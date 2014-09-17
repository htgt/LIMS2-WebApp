package LIMS2::Report::FirstElectroporationProductionDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::FirstElectroporationProductionDetail::VERSION = '0.242';
}
## use critic


use Moose;
use DateTime;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::ProductionDetail );
with qw( LIMS2::ReportGenerator::ColonyCounts );

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';
    $append .= $dt->ymd;

    return 'First Electroporation Production Detail ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    return [
        "Plate Name", "Well Name", "Design Id", "Gene Id", "Gene Symbol",
        "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?",
        "Cassette", "Recombinases", "Cell Line",
        $self->colony_count_column_names,
        "Number Picked", "Number Accepted", "Number XEPs"
    ];
};

override _build_plate_type => sub {
    return 'EP';
};

has '+allele_request_wells_method' => (
    default => 'first_electroporation_wells'
);

__PACKAGE__->meta->make_immutable;

1;

__END__
