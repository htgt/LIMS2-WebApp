package LIMS2::Model::Plugin::Species;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::Species::VERSION = '0.448';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub list_species {
    my $self = shift;

    my @species = map { $_->id }
        $self->schema->resultset('Species')->search( {}, { order_by => { -asc => 'id' } } );

    return \@species;
}

1;

__END__
