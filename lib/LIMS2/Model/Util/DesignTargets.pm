package LIMS2::Model::Util::DesignTargets;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::DesignTargets::VERSION = '0.080';
}
## use critic

use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::DesignTargets

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw( designs_matching_design_target ) ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( any );
use LIMS2::Exception;
use Try::Tiny;

=head2 designs_matching_design_target

For a given design target retrieve any designs that match the design target exon / gene.

First select the designs with the same gene as the design target.
NOTE: The gene names much match exactly, if they do not the design will not be considered.
So it is possible there will be designs that hit the target but do not show up because of
a mismatch in or missing design gene information.

Each of the designs with matching gene targets are then checked to see if they hit the target exon and
a list of these designs is returned.
NOTE: A partial hit on the target exon counts here.

=cut
sub designs_matching_design_target {
    my ( $schema, $design_target ) = @_;

    my @designs_for_exon;

    my @designs = $schema->resultset('Design')->search(
        {
            'genes.gene_id' => $design_target->gene_id,
            species_id      => $design_target->species_id,
        },
        { join => 'genes' },
    );

    for my $design ( @designs ) {
        my $slice = $design->info->target_region_slice;
        my @floxed_exons = try{ @{ $design->info->target_region_slice->get_all_Exons } };

        if ( any { $design_target->ensembl_exon_id eq $_->stable_id } @floxed_exons ) {
            push @designs_for_exon, $design;
        }
    }

    return \@designs_for_exon;
}

1;
