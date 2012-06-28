package LIMS2::Model::Types;

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
