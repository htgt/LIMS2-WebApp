package LIMS2::Model::Types;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Types::VERSION = '0.312';
}
## use critic


use strict;
use warnings FATAL => 'all';

use MooseX::Types -declare => [
    qw(
          ProcessGraphType
  )
];

enum ProcessGraphType, [qw( ancestors descendants)];

1;

__END__
