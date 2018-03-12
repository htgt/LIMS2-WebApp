package LIMS2::Model::Util::Trivial;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Try::Tiny;
use WebAppCommon::Util::FindGene qw( c_find_gene );

requires qw( trivial gene_id species_id );

sub _numeric_to_alpha {
    my $numeric = shift;
    my @alpha;
    while ( $numeric > 0 ) {
        unshift @alpha, ( $numeric - 1 ) % 26;
        $numeric = int( ( $numeric - 1 ) / 26 );
    }
    join q//, map chr( ord('A') + $_ ), @alpha;
}

=head2 trivial_name
    
Calculate a trivial name for an experiment.
To implement, consume this role in a schema class, after providing a
has_one foreign relation to the "trivial" view.

=cut

sub trivial_name {
    my $self    = shift;
    my $trivial = $self->trivial;
    my $gene    = $self->gene_id;
    try {
        $gene = c_find_gene(
             {
                species     => $trivial->species_id,
                search_term => $self->gene_id,
            }
        )->{gene_symbol};
    };
    my @components = ( "${gene}_", $trivial->trivial_crispr );
    if(defined $trivial->trivial_design){
        push @components, _numeric_to_alpha($trivial->trivial_design);
    }
    if(defined $trivial->trivial_experiment){
        push @components, $trivial->trivial_experiment;
    }
    return join q//, @components;
}

1;