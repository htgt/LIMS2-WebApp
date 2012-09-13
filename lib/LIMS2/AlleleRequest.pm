package LIMS2::AlleleRequest;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::AlleleRequest::VERSION = '0.020';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use List::MoreUtils qw( any );
use LIMS2::CassetteFunction qw( satisfies_cassette_function );
use namespace::autoclean;

class_has handled_targeting_types => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
);

sub handles {
    my ( $class, $targeting_type ) = @_;

    return any { $_ eq $targeting_type } @{ $class->handled_targeting_types };
}

has model => (
    is       => 'ro',
    isa      => 'LIMS2::Model',
    required => 1
);

has [ qw( species gene_id ) ] => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub _build_designs {
    my ( $self, $mutation_type ) = @_;

    return $self->model->list_assigned_designs_for_gene(
        {
            species => $self->species,
            gene_id => $self->gene_id,
            type    => $self->design_types_for( $mutation_type )
        }
    );
}

## no critic(RequireFinalReturn)
sub design_types_for {
    my ( $self, $mutation_type ) = @_;

    if ( $mutation_type eq 'ko_first' ) {
        return [ 'conditional', 'artificial-intron', 'intron-replacement' ];
    }
    if ( $mutation_type eq 'deletion' or $mutation_type eq 'insertion' ){
        return $mutation_type;
    }

    $self->model->throw( Implementation => "Unrecognized mutation type: $mutation_type" );
}
## use critic

sub design_wells {
    my ( $self, $design ) = @_;
    return map { $_->output_wells } $design->process_designs_rs->search_related( process => { type_id => 'create_di' } );
}

sub final_vector_wells {
    my ( $self, $design_wells, $cassette_function ) = @_;

    my @final_vector_wells;

    for my $design_well ( @{$design_wells} ) {
        my $it = $design_well->descendants->depth_first_traversal($design_well, 'out');
        while ( my $well = $it->next ) {
            push @final_vector_wells, $well
                if $well->plate->type_id eq 'FINAL' && satisfies_cassette_function( $cassette_function, $well );
        }
    }

    return @final_vector_wells;
}

sub electroporation_wells {
    my ( $self, $vector_wells, $plate_type ) = @_;

    my @electroporation_wells;
    for my $vector_well( @{$vector_wells} ) {
        my $it = $vector_well->descendants->depth_first_traversal($vector_well, 'out');
        while ( my $well = $it->next ) {
            push @electroporation_wells, $well
                if $well->plate->type_id eq $plate_type;
        }
    }

    return @electroporation_wells;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

