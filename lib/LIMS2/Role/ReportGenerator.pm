package LIMS2::Role::ReportGenerator;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Role::ReportGenerator::VERSION = '0.007';
}
## use critic


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

has model => (
    is         => 'ro',
    isa        => 'LIMS2::Model',
    required   => 1,
);

requires qw( _build_name _build_columns iterator );

sub boolean_str {
    my ( $self, $bool ) = @_;

    if ( $bool ) {
        return 'yes';
    }
    else {
        return 'no';
    }
}

1;

__END__

