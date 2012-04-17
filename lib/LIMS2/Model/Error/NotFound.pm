package LIMS2::Model::Error::NotFound;

use strict;
use warnings FATAL => 'all';

use Moose;
use Data::Dump qw( pp );
use namespace::autoclean;

extends qw( LIMS2::Model::Error );

has '+message' => (
    default => 'Entity not found'
);

has entity_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has search_params => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1
);

override as_string => sub {
    my $self = shift;

    my $str = 'No ' . $self->entity_class . ' entity found matching:';

    $str .= "\n\n" . pp( $self->search_params );

    if ( $self->show_stack_trace ) {
        $str .= "\n\n" . $self->stack_trace->as_string;
    }

    return $str;
};

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__
