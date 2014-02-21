package LIMS2::ReportGenerator::Plate::SimpleColumns;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::SimpleColumns::VERSION = '0.164';
}
## use critic


use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

sub base_columns {
    return ( "Well Name", "Design Id", "Gene Id", "Gene Symbol",  "Created By", "Created At" );
}

sub base_data {
    my ( $self, $well ) = @_;

    return (
        $well->name,
        $self->design_and_gene_cols( $well ),
        $well->created_by->name,
        $well->created_at->ymd,
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
