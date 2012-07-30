package LIMS2::AlleleRequest::DoubleTargeted;

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
    is => 'ro',
    isa => 'Str',
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
    qw( first_allele_design_wells second_allele_design_wells
        first_allele_final_vector_wells second_allele_final_vector_wells
  )
] => (
    is         => 'ro',
    isa        => 'ArrayRef[LIMS2::Model::Schema::Result::Well]',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_first_allele_design_wells {
    my $self = shift;
    [ map { $self->design_wells($_) } @{$self->first_allele_designs} ];
}

sub _build_second_allele_design_wells {
    my $self = shift;
    [ map { $self->design_wells($_) } @{$self->second_allele_designs} ];
}

sub _build_first_allele_final_vector_wells {
    my $self = shift;
    
}

__PACKAGE__->meta->make_immutable;

1;

__END__
