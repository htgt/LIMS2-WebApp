package LIMS2::Model::Plugin::Chromosome;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

requires qw( schema check_params throw retrieve log trace );

sub get_chr_id_for_name {
    my $self = shift;
    my $species = shift;
    my $chr_name = shift;

    my $chr_id = $schema->resultset('Chromosome')->find( {
            'species_id' => $species,
            'name'       => $chr_name,
        }
    );
    return $chr_id->id;
}

1;

__END__
