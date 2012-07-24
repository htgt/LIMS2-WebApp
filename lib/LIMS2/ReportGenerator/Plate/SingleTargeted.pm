package LIMS2::ReportGenerator::Plate::SingleTargeted;

use strict;
use warnings;

use Moose;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

sub base_columns {
    return ( "Well Name", "Design Id", "Gene Id", "Gene Symbol",  "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?" );
}

sub base_data {
    my ( $self, $well ) = @_;

    my $design        = $well->design;
    my @gene_ids      = uniq map { $_->gene_id } $design->genes;
    my @gene_symbols  = uniq map {
        $self->model->retrieve_gene( { species => $self->species, search_term => $_ } )->{gene_symbol}
    } @gene_ids;

    return (
        $well->name,
        $design->id,
        join( q{/}, @gene_ids ),
        join( q{/}, @gene_symbols ),
        $well->created_by->name,
        $well->created_at->ymd,
        ( $well->assay_pending ? $well->assay_pending->ymd : '' ),
        ( $well->assay_complete ? $well->assay_complete->ymd : '' ),
        $self->boolean_str( $well->is_accepted )
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
