package LIMS2::Report::SecondElectroporationProductionDetail;

use Moose;
use DateTime;
use List::MoreUtils qw( uniq );
use Iterator::Simple qw( iter imap iflatten );
use LIMS2::Exception::Implementation;
use LIMS2::Report::SEPPlate;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

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

override iterator => sub {
    my $self = shift;

    my $sep_plate_rs = $self->model->schema->resultset( 'Plate' )->search_rs(
        {
            'me.type_id'    => 'SEP',
            'me.species_id' => $self->species
        }
    );

    return iflatten imap { $self->plate_report_iterator( $_ ) } iter $sep_plate_rs;
};

sub plate_report_iterator {
    my ( $self, $plate ) = @_;

    my $report = LIMS2::Report::SEPPlate->new( model => $self->model, species => $self->species, plate => $plate );

    return imap { unshift @{$_}, $plate->name; $_ } $report->iterator;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
