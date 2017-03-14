package LIMS2::AlleleRequest::DoubleTargeted;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::AlleleRequest::DoubleTargeted::VERSION = '0.450';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::ClassAttribute;
use namespace::autoclean;

extends qw( LIMS2::AlleleRequest );

class_has '+handled_targeting_types' => (
    default => sub { [ 'double_targeted' ] }
);

has [ qw( first_allele_mutation_type first_allele_cassette_function second_allele_mutation_type second_allele_cassette_function ) ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has [ qw( first_allele_designs second_allele_designs ) ] => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Design]',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_first_allele_designs {
    my $self = shift;
    return $self->_build_designs( $self->first_allele_mutation_type );
}

sub _build_second_allele_designs {
    my $self = shift;
    return $self->_build_designs( $self->second_allele_mutation_type );
}

has [
    qw( first_allele_design_wells   second_allele_design_wells
        first_allele_vector_wells   second_allele_vector_wells
        first_electroporation_wells second_electroporation_wells
        first_allele_dna_wells      second_allele_dna_wells
        first_allele_pick_wells     second_allele_pick_wells
  )
] => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Well]',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_first_allele_design_wells {
    my $self = shift;
    return [ map { $self->design_wells($_) } @{$self->first_allele_designs} ];
}

sub _build_second_allele_design_wells {
    my $self = shift;
    return [ map { $self->design_wells($_) } @{$self->second_allele_designs} ];
}

sub _build_first_allele_vector_wells {
    my $self = shift;
    return [ $self->final_vector_wells( $self->first_allele_design_wells, $self->first_allele_cassette_function ) ];
}

sub _build_second_allele_vector_wells {
    my $self = shift;
    return [ $self->final_vector_wells( $self->second_allele_design_wells, $self->second_allele_cassette_function ) ];
}

sub all_vector_wells {
    my $self = shift;
    return [ @{$self->first_allele_vector_wells}, @{$self->second_allele_vector_wells} ];
}

sub _build_first_allele_dna_wells {
    my $self = shift;
    return [ $self->dna_wells( $self->first_allele_vector_wells ) ];
}

sub _build_second_allele_dna_wells {
    my $self = shift;
    return [ $self->dna_wells( $self->second_allele_vector_wells ) ];
}

sub all_dna_wells {
    my $self = shift;
    return [ @{$self->first_allele_dna_wells}, @{$self->second_allele_dna_wells} ];
}

sub _build_first_electroporation_wells {
    my $self = shift;
    return [ $self->electroporation_wells( $self->first_allele_vector_wells, 'EP' ) ];
}

sub _build_second_electroporation_wells {
    my $self = shift;

    # The SEP wells we are interested in are in the intersection of
    # first allele descendants and second allele descendants

    my %is_first = map { $_->id => 1 } $self->electroporation_wells( $self->first_allele_vector_wells, 'SEP' );

    my @intersection = grep { $is_first{ $_->id } } $self->electroporation_wells( $self->second_allele_vector_wells, 'SEP' );

    return \@intersection;
}

sub _build_first_allele_pick_wells {
    my $self = shift;
    return [ $self->pick_wells( $self->first_electroporation_wells, 'EP_PICK' ) ];
}

sub _build_second_allele_pick_wells {
    my $self = shift;
    return [ $self->pick_wells( $self->second_electroporation_wells, 'SEP_PICK' ) ];
}

__PACKAGE__->meta->make_immutable;

1;

__END__
