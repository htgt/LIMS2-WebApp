package LIMS2::ReportGenerator::Plate::DoubleTargeted;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::Plate::DoubleTargeted::VERSION = '0.442';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator::Plate );

has show_cassette_info => (
    is         => 'rw',
    isa        => 'Bool',
    default    => 1,
);

has show_recombinase_info => (
    is         => 'rw',
    isa        => 'Bool',
    default    => 1,
);

has show_crispr_info => (
    is         => 'rw',
    isa        => 'Bool',
    default    => 0,
);

sub base_columns {
    my ($self) = @_;
# acs - 20_05_13 - redmine 10545 - add cassette resistance
#    my @allele_cols = ( "Vector", "Design", "Gene Id", "Gene Symbol", "Cassette", "Recombinases" );
    my @allele_cols = ( "Vector", "Design ID", "Design Type", "Gene Id", "Gene Symbol", "Gene Sponsors");

    if($self->show_cassette_info){
        push @allele_cols, ("Cassette", "Cassette Resistance", "Cassette Type");
    }

    if($self->show_recombinase_info){
        push @allele_cols, ("Vector Recombinases", "Cell Recombinases");
    }

    if($self->show_crispr_info){
        push @allele_cols, "Crispr Wells";
    }

    return ( "Well ID", "Well Name","Cell Line",
        map( { "First $_" } @allele_cols ),
		map( { "Second $_" } @allele_cols ),
        "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?", "Report?",
    );
}

sub base_data {
    my ( $self, $well ) = @_;

    my $first_allele  = $well->first_allele;
    my $second_allele = $well->second_allele;

    my @data = (
        $well->id,
        $well->name,
        $well->first_cell_line->name,
    );

    foreach my $allele ( ($first_allele, $second_allele) ){
        push @data, (
            $allele->final_vector->as_string,
            $self->design_and_gene_cols( $allele ),
        );

        if($self->show_cassette_info){
            push @data, (
               $allele->cassette->name,
               $allele->cassette->resistance,
               ( $allele->cassette->promoter ? 'promoter' : 'promoterless' )
            );
        }

        if($self->show_recombinase_info){
            push @data, (
                join( q{/}, @{ $allele->vector_recombinases } ),
                join( q{/}, @{ $allele->cell_recombinases } ),
            );
        }

        if($self->show_crispr_info){
            push @data, (
                _format_well_names($allele->parent_crispr_wells)
            );
        }
    }

    push @data, (
        $well->created_by->name,
        $well->created_at->ymd,
        ( $well->assay_pending ? $well->assay_pending->ymd : '' ),
        ( $well->assay_complete ? $well->assay_complete->ymd : '' ),
        $self->boolean_str( $well->is_accepted ),
        $self->boolean_str( $well->to_report ),
    );

    return @data;
}

sub _format_well_names{
    my (@wells) = @_;
    my @well_names = map { $_->plate_name."[".$_->well_name."]" } @wells;
    return join ",", @well_names;
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
