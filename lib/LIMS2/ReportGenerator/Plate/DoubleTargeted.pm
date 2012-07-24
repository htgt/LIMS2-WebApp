package LIMS2::ReportGenerator::Plate::DoubleTargeted;

use strict;
use warnings FATAL => 'all';

use Moose;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

sub base_columns {
    my @allele_cols = ( "Design", "Gene Id", "Gene Symbol", "Cassette", "Recombinases" );
    return ( "Well Name", "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?",
             map( { "First Allele $_" } @allele_cols ),
             map( { "Second Alelle $_" } @allele_cols )
         );
}

sub base_data {
    my ( $self, $well ) = @_;

    my $first_allele  = $well->first_allele;
    my $second_allele = $well->second_allele;

    return (
        $well->name,
        $well->created_by->name,
        $well->created_at->ymd,
        ( $well->assay_pending ? $well->assay_pending->ymd : '' ),
        ( $well->assay_complete ? $well->assay_complete->ymd : '' ),
        $self->boolean_str( $well->is_accepted ),
        $self->design_and_gene_cols( $first_allele ),
        $first_allele->cassette->name,
        join( q{/}, @{ $first_allele->recombinases } ),
        $self->design_and_gene_cols( $second_allele ),
        $second_allele->cassette->name,
        join( q{/}, @{ $second_allele->recombinases } ),
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
