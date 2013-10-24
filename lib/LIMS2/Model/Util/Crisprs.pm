package LIMS2::Model::Util::Crisprs;
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
use Data::Printer;

=head2 crispr_pick

Takes input from form where users pick a crispr or crispr pair to go with designs.
We then validate the selection and persist the link between the design and crispr(s).

=cut
sub crispr_pick {
    my ( $model, $request_params, $species_id ) = @_;
    my %logs;

    my $default_assembly = $model->schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species_id } )->assembly_id;

    # Pairs
    if ( $request_params->{crispr_types} eq 'pair' ) {
        my $checked_design_crispr_links = parse_request_param( $request_params, 'crispr_pair_pick' );
        my $existing_design_crispr_links = parse_request_param( $request_params, 'design_crispr_pair_link' );

        # create new links
        my $create_links = compare_design_crispr_links( $checked_design_crispr_links,
            $existing_design_crispr_links, 'crispr_pair_id' );

        # delete links
        my $delete_links = compare_design_crispr_links( $existing_design_crispr_links,
            $checked_design_crispr_links, 'crispr_pair_id' );

        my ( $create_log, $create_fail_log )
            = create_crispr_pair_design_links( $model, $create_links, $default_assembly );
        my ( $delete_log, $delete_fail_log ) = delete_crispr_pair_design_links( $model, $delete_links );
        $logs{'create'} = $create_log;
        $logs{'delete'} = $delete_log;
        $logs{'create_fail'} = $create_fail_log;
        $logs{'delete_fail'} = $delete_fail_log;
    }
    elsif ( $request_params->{crispr_types} eq 'single' ) {
        #TODO single crisprs sp12 Wed 23 Oct 2013 11:01:31 BST
    }

    return \%logs;
}

=head2 parse_request_param

Find a specific named request parameter and make sure to return a array ref.

=cut
sub parse_request_param {
    my ( $request_params, $name ) = @_;

    my $param = $request_params->{$name};
    return {} unless $param;

    my @link_lines;
    if ( my $ref_type = ref($param) ) {
        if ( $ref_type eq 'ARRAY' ) {
            @link_lines = @{ $param };
        }
        else {
            LIMS2::Exception->throw(
                "Unexpected ref type when working with request param: $name ( $ref_type )");
        }
    }
    else {
        @link_lines = ( $param );
    }

    my %links;
    for my $link ( @link_lines ) {
        my ( $crispr_id, $design_id ) = split /:/, $link;
        $links{$design_id}{$crispr_id} = undef;
    }

    return \%links;
}

=head2 compare_design_crispr_links


=cut
sub compare_design_crispr_links {
    my ( $orig, $new, $crispr_id_type ) = @_;

    my @change_links;
    for my $design_id ( keys %{ $orig } ) {
        my $orig_links = $orig->{ $design_id };

        if ( my $new_links = $new->{ $design_id } ) {
            # we have both orig and new links, compare
            for my $crispr_id ( keys %{ $orig_links } ) {
                unless ( exists $new_links->{ $crispr_id } ) {
                    push @change_links,
                        { design_id => $design_id, $crispr_id_type => $crispr_id };
                }
            }
        }
        # no new links, change all specified links
        else {
            for my $crispr_id ( keys %{ $orig_links } ) {
                push @change_links,
                    { design_id => $design_id, $crispr_id_type => $crispr_id };
            }
        }
    }

    return \@change_links;
}

=head2 create_crispr_pair_design_links

Create a link between a design and a crispr pair after validating that the
crispr pair and design hit the same location.

=cut
sub create_crispr_pair_design_links {
    my ( $model, $create_links, $default_assembly ) = @_;
    my ( @create_log, @fail_log );

    for my $datum ( @{ $create_links } ) {
        my $design = $model->retrieve_design( { id => $datum->{design_id} } );
        my $crispr_pair = $model->schema->resultset( 'CrisprPair' )->find(
            { id => $datum->{crispr_pair_id} },
            { prefetch => [ 'left_crispr', 'right_crispr' ] },
        );
        LIMS2::Exception->throw( 'Can not find crispr pair: ' . $datum->{crispr_pair_id} )
            unless $crispr_pair;

        try{
            crispr_pair_hits_design( $design, $crispr_pair, $default_assembly );
        }
        catch {
            ERROR( 'Crispr pair cannot be linked to design: ' . $_ );
            push @fail_log,
                  'Additional validation failed between design & crispr pair ' . p(%$datum);
        };

        my $crispr_design = $model->schema->resultset( 'CrisprDesign' )->find_or_create(
            {
                design_id      => $design->id,
                crispr_pair_id => $crispr_pair->id,
            }
        );
        INFO('Crispr design record created: ' . $crispr_design->id );

        push @create_log, 'Linked design & crispr pair ' . p(%$datum);
    }

    return ( \@create_log, \@fail_log );
}

=head2 delete_crispr_pair_design_links

Delete a link between a crispr pair and a design.

=cut
sub delete_crispr_pair_design_links {
    my ( $model, $delete_links ) = @_;
    my ( @delete_log, @fail_log );

    for my $datum ( @{ $delete_links } ) {
        my $crispr_design = $model->schema->resultset( 'CrisprDesign' )->find( $datum );
        unless ( $crispr_design ) {
            ERROR( 'Unable to find crispr_design link ' . p(%$datum) );
            push @fail_log, 'Failed to find design & crispr pair link: ' . p(%$datum);
            next;
        }
        if ( $crispr_design->delete ) {
            INFO( 'Deleted crispr_design record ' . $crispr_design->id );
            push @delete_log, 'Deleted link between design & crispr_pair: ' . p(%$datum);
        }
        else {
            ERROR( 'Failed to delete crispr_design record ' . $crispr_design->id );
            push @fail_log, 'Failed to delete design & crispr_pair link ' . p(%$datum);
        }
    }

    return ( \@delete_log, \@fail_log );
}

=head2 crispr_pair_hits_design

Check that the crispr pairs 2 crisprs location matches with the designs target region.

=cut
sub crispr_pair_hits_design {
    my ( $design, $crispr_pair, $default_assembly ) = @_;

    my $design_info = LIMS2::Model::Util::DesignInfo->new(
        design           => $design,
        default_assembly => $default_assembly,
    );

    unless (
        crispr_hits_design( $design, $crispr_pair->left_crispr, $default_assembly, $design_info ) )
    {
        LIMS2::Exception->throw( 'Left crispr ' . $crispr_pair->left_crispr->id
                . ' from crispr pair ' . $crispr_pair->id . ' does not hit design '
                . $design->id );
    }

    unless (
        crispr_hits_design( $design, $crispr_pair->right_crispr, $default_assembly, $design_info ) )
    {
        LIMS2::Exception->throw( 'Right crispr ' . $crispr_pair->right_crispr->id
                . ' from crispr pair ' . $crispr_pair->id . ' does not hit design '
                . $design->id );
    }

    return 1;
}

=head2 crispr_hits_design

Check that the crispr location matches with the designs target region.

=cut
sub crispr_hits_design {
    my ( $design, $crispr, $default_assembly, $design_info ) = @_;

    $design_info ||= LIMS2::Model::Util::DesignInfo->new(
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

1;
