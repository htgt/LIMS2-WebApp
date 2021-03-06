package LIMS2::Model::Plugin::Assembly;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

#requires qw( schema check_params throw retrieve log trace );



sub get_species_default_assembly {
    my $self = shift;
    my $species = shift;

    my $assembly_r = $self->schema->resultset('SpeciesDefaultAssembly')->find( { species_id => $species } );

    return $assembly_r->assembly_id || undef;
}

1;
