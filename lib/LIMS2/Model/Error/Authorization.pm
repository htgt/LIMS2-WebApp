package LIMS2::Model::Error::Authorization;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends qw( LIMS2::Model::Error );

has '+message' => (
    default => 'You are not authorized to perform this operation'
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__
