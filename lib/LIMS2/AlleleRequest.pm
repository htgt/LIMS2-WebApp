package LIMS2::AlleleRequest;

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use List::MoreUtils qw( any );
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

    if ( $mutation_type eq 'ko first' ) {
        return [ 'conditional', 'artificial-intron', 'intron-replacement' ];
    }

    $self->model->throw( Implementation => "Unrecognized mutation type: $mutation_type" );    
}
## use critic

sub design_wells {
    my ( $self, $design ) = @_;
    return map { $_->output_wells } $design->process_designs_rs->search_related( process => { type_id => 'create_di' } );
}

    

# Input:
#
# gene_id: Snf8 ( MGI:1343161 )
# targeting type: double targeting
# first allele Mutation type: ko first
# first allele cassette function: ko first
# second allele mutation type: conditional
# second allele cassette function: reporter only (conditional + cre)

# Output:
#
# Designs
# Design wells
# Final vector wells for 1st allele
# Final vector wells for 2nd allele
# First EP
# Second EP

__PACKAGE__->meta->make_immutable;

1;

__END__

