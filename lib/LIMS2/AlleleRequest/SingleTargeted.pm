package LIMS2::AlleleRequest::SingleTargeted;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::AlleleRequest::SingleTargeted::VERSION = '0.340';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use namespace::autoclean;

extends qw( LIMS2::AlleleRequest );

class_has '+handled_targeting_types' => (
    default => sub { [ 'single_targeted' ] }
);

has [ qw( mutation_type cassette_function ) ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has gene_designs => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Design]',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_gene_designs {
    my $self = shift;
    return $self->_build_designs( $self->mutation_type );
}

has [
    qw( allele_design_wells allele_vector_wells
        allele_dna_wells    allele_electroporation_wells
        allele_pick_wells
    )
] => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Well]',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_allele_design_wells {
    my $self = shift;
    return [ map { $self->design_wells($_) } @{$self->gene_designs} ];
}

sub _build_allele_vector_wells {
    my $self = shift;
    return [ $self->final_vector_wells( $self->allele_design_wells, $self->cassette_function ) ];
}

sub _build_allele_dna_wells {
    my $self = shift;
    return [ $self->dna_wells( $self->allele_vector_wells ) ];
}

sub _build_allele_electroporation_wells {
    my $self = shift;
    return [ $self->electroporation_wells( $self->allele_vector_wells, 'EP' ) ];
}

sub all_vector_wells {
    my $self = shift;
    return [ @{$self->allele_vector_wells} ];
}

sub _build_allele_pick_wells {
    my $self = shift;
    return [ $self->pick_wells( $self->allele_electroporation_wells, 'EP_PICK' ) ];
}


__PACKAGE__->meta->make_immutable;

1;

__END__
