package LIMS2::Model::Util::Trivial;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::Trivial::VERSION = '0.504';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Try::Tiny;
use WebAppCommon::Util::FindGene qw( c_find_gene );

requires qw( trivial gene_id species_id );

=head2 numeric_to_alpha

convert a number to a base-26 (alphabetical) representation
e.g. A, B, ... Z, AA, AB...

=cut

sub numeric_to_alpha {
    my $numeric = shift;
    my @alpha;
    while ( $numeric > 0 ) {
        # take the least significant (base-26) digit, and add it to the array *in front*
        # of all the previous least significant digits
        unshift @alpha, ( $numeric - 1 ) % 26;
        $numeric = int( ( $numeric - 1 ) / 26 );
    }

    # convert each base-26 digit into its alphabetical representation
    return join q//, map { chr( ord('A') + $_ ) } @alpha;
}

=head2 trivial_name
    
Calculate a trivial name for an experiment.
To implement, consume this role in a schema class, after providing a
has_one foreign relation to the "trivial" view.

=cut

sub trivial_name {
    my $self    = shift;
    if ( $self->assigned_trivial ) {
        return $self->assigned_trivial;
    }
    my $trivial = $self->trivial;
    if ( not defined $trivial ) {
        return q//;
    }
    my $gene = $self->gene_id;
    try {
        $gene = c_find_gene(
            {   species     => $trivial->species_id,
                search_term => $self->gene_id,
            }
        )->{gene_symbol};
    };
    my @components = ( "${gene}_", $trivial->trivial_crispr );
    if ( defined $trivial->trivial_design ) {
        push @components, numeric_to_alpha( $trivial->trivial_design );
    }
    if ( defined $trivial->trivial_experiment ) {
        push @components, $trivial->trivial_experiment;
    }
    return join q//, @components;
}

1;
