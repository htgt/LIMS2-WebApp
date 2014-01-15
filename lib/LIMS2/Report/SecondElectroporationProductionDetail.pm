package LIMS2::Report::SecondElectroporationProductionDetail;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Report::SecondElectroporationProductionDetail::VERSION = '0.143';
}
## use critic


use Moose;
use DateTime;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::ProductionDetail );

has species => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

override _build_name => sub {
    my $self = shift;

    my $dt = DateTime->now();
    my $append = $self->has_sponsor ? ' - Sponsor ' . $self->sponsor . ' ' : '';
    $append .= $dt->ymd;

    return 'Second Electroporation Production Detail ' . $append;
};

override _build_columns => sub {
    my $self = shift;

    my @allele_cols = ( "Vector", "Design", "Gene Id", "Gene Symbol", "Cassette", "Recombinases" );
    return [ "Plate Name", "Well Name", "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?",
             map( { "First Allele $_" } @allele_cols ),
             map( { "Second Allele $_" } @allele_cols ),
             'Second Allele Cassette Type',
             'Number Picked', 'Number Accepted'
         ];
};

override _build_plate_type => sub {
    'SEP';
};

has '+allele_request_wells_method' => (
    default => 'second_electroporation_wells'
);

__PACKAGE__->meta->make_immutable;

1;

__END__
