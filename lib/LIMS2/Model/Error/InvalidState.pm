package LIMS2::Model::Error::InvalidState;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends qw( LIMS2::Model::Error );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__
