package LIMS2::Role::ReportGenerator;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Iterator::Simple;
use namespace::autoclean;

has name => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has columns => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    init_arg   => undef,
    lazy_build => 1
);

requires qw( _build_name _build_columns iterator );

1;

__END__

