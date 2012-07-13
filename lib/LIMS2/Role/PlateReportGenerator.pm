package LIMS2::Role::PlateReportGenerator;

use strict; 
use warnings;

use Moose::Role;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

has plate_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub base_columns {
    return ( "Well Name", "Design Id", "Gene Id", "Gene Symbol",  "Created By", "Created At", "Assay Pending", "Assay Complete", "Accepted?" );
}

sub base_data {
    my ( $self, $well ) = @_;

    my $design        = $well->design;
    my @gene_ids      = uniq map { $_->gene_id } $design->genes;
    my @gene_symbols  = uniq map { $self->model->retrieve_gene( { gene => $_ } )->{marker_symbol} } @gene_ids;

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

sub qc_result_cols {
    my ( $self, $well ) = @_;

    my $result = $well->well_qc_sequencing_result;

    if ( $result ) {
        return (
            $result->test_result_url,
            $result->valid_primers,
            $self->boolean_str( $result->mixed_reads ),
            $self->boolean_str( $result->pass )
        );
    }
    
    return ('')x4;
}

sub ancestor_cols {
    my ( $self, $well, $plate_type ) = @_;

    my $ancestors = $well->ancestors->depth_first_traversal($well, 'in');

    while ( my $ancestor = $ancestors->next ) {
        if ( $ancestor->plate->type_id eq $plate_type ) {
            return (
                $ancestor->as_string,
                $self->qc_result_cols( $ancestor )
            );
        }
    }

    return ('')x5;
}

1;

__END__
