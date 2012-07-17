package LIMS2::Role::PlateReportGenerator;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Role::PlateReportGenerator::VERSION = '0.007';
}
## use critic


use strict;
use warnings;

use Moose::Role;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

with qw( LIMS2::Role::ReportGenerator );

requires qw( plate_type );

has plate_name => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

has plate_id => (
    is       => 'ro',
    isa      => 'Int'
);

has plate => (
    is         => 'ro',
    isa        => 'LIMS2::Model::Schema::Result::Plate',
    lazy_build => 1
);

sub _build_plate {
    my $self = shift;

    my %search = ( type => $self->plate_type );

    if ( $self->plate_id ) {
        $search{id} = $self->plate_id;
    }
    elsif ( $self->plate_name ) {
        $search{name} = $self->plate_name;
    }
    else {
        LIMS2::Exception::Implementation->throw( "PlateReportGenerator requires one of plate, plate_name, or plate_id be specified" );
    }

    return $self->model->retrieve_plate( \%search );
}

sub _build_plate_name {
    my $self = shift;

    return $self->plate->name;
}

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
