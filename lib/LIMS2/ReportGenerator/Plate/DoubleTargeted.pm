package LIMS2::ReportGenerator::Plate::DoubleTargeted;

use strict;
use warnings FATAL => 'all';

use Moose;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

sub base_columns {
# acs - 20_05_13 - redmine 10545 - add cassette resistance
#    my @allele_cols = ( "Vector", "Design", "Gene Id", "Gene Symbol", "Cassette", "Recombinases" );
    my @allele_cols = ( "Vector", "Design ID", "Design Type", "Gene Id", "Gene Symbol", "Gene Sponsors", "Cassette", "Cassette Resistance", "Vector Recombinases", "Cell Recombinases" );
    return ( "Well Name", "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?",
        map( { "First Allele $_" } @allele_cols ),
		map( { "Second Alelle $_" } @allele_cols ),
		 'Second Allele Cassette Type'
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
        $first_allele->final_vector->as_string,
        $self->design_and_gene_cols( $first_allele ),
        $first_allele->cassette->name,
        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        $first_allele->cassette->resistance,
        join( q{/}, @{ $first_allele->vector_recombinases } ),
        join( q{/}, @{ $first_allele->cell_recombinases } ),
        $second_allele->final_vector->as_string,
        $self->design_and_gene_cols( $second_allele ),
        $second_allele->cassette->name,
        # acs - 20_05_13 - redmine 10545 - add cassette resistance
        $second_allele->cassette->resistance,
        join( q{/}, @{ $second_allele->vector_recombinases } ),
        join( q{/}, @{ $second_allele->cell_recombinases } ),
        ( $second_allele->cassette->promoter ? 'promoter' : 'promoterless' ),
    );
}

# Pre-fetch the ancestors for the first and second allele representative wells
# for each well on the plate to speed up allele specific queries
after 'prefetch_well_ancestors' => sub {
    my $self = shift;
    my @allele_wells;
    foreach my $well ($self->plate->wells){
        push @allele_wells, $well->first_allele;
        push @allele_wells, $well->second_allele;
    }

    my @well_ids = map { $_->id } @allele_wells;
    my $well_ancestors = $self->model->fast_get_well_ancestors(@well_ids);
    foreach my $this_well (@allele_wells){
        $this_well->set_ancestors( $well_ancestors->{ $this_well->id } );
    }

    return;
};

__PACKAGE__->meta->make_immutable;

1;

__END__
