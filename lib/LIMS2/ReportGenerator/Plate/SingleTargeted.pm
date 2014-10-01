package LIMS2::ReportGenerator::Plate::SingleTargeted;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::SingleTargeted::VERSION = '0.250';
}
## use critic


use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

sub base_columns {
    return ( "Well Name", "Design Id", "Gene Id", "Gene Symbol", "Gene Sponsors", "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?", "Genbank File" );
}

sub base_data {
    my ( $self, $well, $crispr, $args ) = @_;

    my @base_data = (
        $well->name,
        $self->design_and_gene_cols($well,$crispr),
        $well->created_by->name,
        $well->created_at->ymd,
        ( $well->assay_pending ? $well->assay_pending->ymd : '' ),
        ( $well->assay_complete ? $well->assay_complete->ymd : '' ),
        $self->boolean_str( $well->is_accepted ),
    );

    unless ( $args || $args->{no_eng_seq_link} ) {
        push @base_data, $self->catalyst->uri_for( '/user/well_eng_seq', $well->id );
    }

    return @base_data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
