package LIMS2::Model::Util::Crisprs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::Crisprs::VERSION = '0.113';
}
## use critic

use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::Crisprs

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [
        qw(
            crispr_pick
            crispr_hits_design
            )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( none );
use LIMS2::Exception;
use LIMS2::Model::Util::DesignInfo;
use Try::Tiny;

=head2 crispr_pick

Takes input from form where users pick a crispr or crispr pair to go with designs.
We then validate the selection and persist the link between the design and crispr(s).

=cut
sub crispr_pick {
    my ( $model, $crispr_picks, $design_crispr_link, $species_id ) = @_;
    my %design_crisprs;

    my $default_assembly = $model->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species_id } )->assembly_id;

    for my $pick ( @{ $crispr_picks } ) {
        my ( $crispr_id, $design_id ) = split /:/, $pick;
        push @{ $design_crisprs{ $design_id } }, $crispr_id;
    }

    for my $design_id ( keys %design_crisprs ) {
        my $design = $model->retrieve_design( { id => $design_id } );

        my @crisprs
            = map { $model->retrieve_crispr( { id => $_ } ) } @{ $design_crisprs{$design_id} };

        LIMS2::Exception->throw( 'Picked more than 2 crisprs for design: '. $design->id )
            if scalar(@crisprs) > 2;

        for my $crispr ( @crisprs ) {
            LIMS2::Exception->throw( 'Crispr ' . $crispr->id . ' does not hit design ' . $design->id )
                unless crispr_hits_design( $design, $crispr, $species_id );
        }

        # one crispr picked for design
        if ( scalar(@crisprs) == 1 ) {
            my $crispr_design = $model->schema->resultset( 'CrisprDesign' )->find_or_create(
                {
                    design_id => $design->id,
                    crispr_id => $crisprs[0]->id,
                }
            );
        }
        # got a pair of crisprs
        elsif ( scalar(@crisprs) == 2 ) {
            my $crispr_pair = check_crispr_pair( $model, \@crisprs );
            my $crispr_design = $model->schema->resultset( 'CrisprDesign' )->find_or_create(
                {
                    design_id      => $design->id,
                    crispr_pair_id => $crispr_pair->id,
                }
            );
        }
    }

    return;
}

=head2 crispr_hits_design

Check that the crispr location matches with the designs target region.

=cut
sub crispr_hits_design {
    my ( $design, $crispr, $default_assembly ) = @_;

    my $design_info = LIMS2::Model::Util::DesignInfo->new(
        design           => $design,
        default_assembly => $default_assembly,
    );

    my $crispr_locus = $crispr->loci( { assembly_id => $default_assembly } )->first;

    if (   $crispr_locus->chr_start  > $design_info->target_region_start
        && $crispr_locus->chr_end    < $design_info->target_region_end
        && $crispr_locus->chr->name eq $design_info->chr_name
    ) {
        return 1;
    }

    return;
}

=head2 check_crispr_pair

Check the 2 crisprs are a valid crispr pair.
Return a crispr_pair object.

=cut
sub check_crispr_pair {
    my ( $model, $crisprs ) = @_;

    if ( none{ $_->pam_right } @{ $crisprs } && none{ !$_->pam_right } @{ $crisprs } ) {
        LIMS2::Exception->throw( "Must pick both a left and right crispr to get a valid crispr pair" );
    }
    my ( $right_crispr ) = grep{ $_->pam_right } @{ $crisprs };
    my ( $left_crispr ) = grep{ !$_->pam_right } @{ $crisprs };

    my $crispr_pair = $model->schema->resultset( 'CrisprDesign' )->find(
        {
            left_crispr_id  => $left_crispr->id,
            right_crispr_id => $right_crispr->id,
        }
    );

    unless ( $crispr_pair ) {
        LIMS2::Exception->throw( 'Unable to find crispr pair, left: '
                . $left_crispr->id . ' right: ' . $right_crispr->id );
    }

    return $crispr_pair;
}

1;
