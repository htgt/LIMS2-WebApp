package LIMS2::ReportGenerator;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::ReportGenerator::VERSION = '0.010';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose;
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

sub _build_name {
    confess( "_build_name() must be implemented by a subclass" );
}

sub _build_columns {
    confess( "_build_columns() must be implemented by a subclass" );
}

sub iterator {
    confess( "iterator() must be implemented by a subclass" );
}

sub boolean_str {
    my ( $self, $bool ) = @_;

    if ( $bool ) {
        return 'yes';
    }
    else {
        return 'no';
    }
}

__PACKAGE__->meta->make_immutable();

1;

__END__

