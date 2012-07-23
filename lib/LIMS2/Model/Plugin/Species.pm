package LIMS2::Model::Plugin::Species;

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
