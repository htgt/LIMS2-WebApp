package LIMS2::ReportGenerator::Plate;

use strict;
use warnings;

use Moose;
use MooseX::ClassAttribute;
use List::MoreUtils qw( uniq );
use namespace::autoclean;

extends qw( LIMS2::ReportGenerator );

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
    lazy_build => 1,
    handles    => {
        species => 'species_id'
    }
);

sub plate_types {
    confess( "plate_types() must be implemented by a subclass" );
}

sub handles_plate_type {
    my ( $class, $plate_type ) = @_;

    for my $handled_plate_type ( @{ $class->plate_types } ) {
        return 1 if $plate_type eq $handled_plate_type;
    }

    return;    
}

sub _build_plate {
    my $self = shift;

    my %search = ( type => $self->plate_types );

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
    confess "base_columns() must be implemented by a subclass";
}

sub base_data {
    confess "base_data() must be implemented by a subclass";
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

__PACKAGE__->meta->make_immutable;

1;

__END__
