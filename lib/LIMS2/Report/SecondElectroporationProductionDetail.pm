package LIMS2::Report::SecondElectroporationProductionDetail;

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
    my $dt = DateTime->now();
    return 'Second Electroporation Production Detail ' . $dt->ymd;
};

override _build_columns => sub {
    my $self = shift;

    my @allele_cols = ( "Vector", "Design", "Gene Id", "Gene Symbol", "Cassette", "Recombinases" );
    return [ "Plate Name", "Well Name", "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?",
             map( { "First Allele $_" } @allele_cols ),
             map( { "Second Alelle $_" } @allele_cols ),
             'Second Allele Cassette Type',
             'Number Picked', 'Number Accepted'
         ];
};

override _build_plate_type => sub {
    'SEP';
};

__PACKAGE__->meta->make_immutable;

1;

__END__
