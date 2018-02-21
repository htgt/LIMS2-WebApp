package LIMS2::Model::Plugin::CrisprSummaries;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Plugin::CrisprSummaries::VERSION = '0.488';
}
## use critic


use Moose::Role;
use LIMS2::Model;
use LIMS2::Model::Util::Crisprs qw( crisprs_for_design );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );

use strict;
use warnings;

BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $DEBUG } );
    }
}

=head

This module uses ProcessTree to construct find the descendants for a list of CRISPR wells

The input can be a list (arrayref) of genes, design IDs, crispr IDs or CRISPR well IDs

The process graphs are returned as a hashref starting from gene, design, crispr or CRISPR well
depending on the input, and leading to well resultsets for each plate type
e.g
<gene id>
  <design id>
    all_crisprs
      [ crisprs array ]
    all_pairs
      [ crispr_pairs array ]
    plated_pairs
      <pair id>
        left_id
          <left crispr id>
        right_id
          <right crispr id>
    plated_crisprs
      <crispr id>
        <crispr well id>
          crispr_well_created
            DateTime
          CRISPR_V
            [ well resultset ]
          DNA
            [ well resultset ]
          child_well_id_list
            [ well ids ]

=cut

sub get_crispr_summaries_for_genes{
    my ($self, $params) = @_;

    ref $params->{id_list} eq ref []
        or die "id_list must be an arrayref";

    my $result = {};
    my $gene_id_for_design = {};

    my @design_id_list;
    DEBUG "Fetching assigned designs for genes";
    foreach my $gene_id (@{ $params->{id_list} }){
        my $designs = $self->c_list_assigned_designs_for_gene( { gene_id => $gene_id, species => $params->{species} } );
        foreach my $design (@$designs){
            $gene_id_for_design->{$design->id} = $gene_id;
            push @design_id_list, $design->id;
        }
    }
    DEBUG scalar(@design_id_list)." Designs found";

    my $summaries = $self->get_crispr_summaries_for_designs({ id_list => \@design_id_list });

    foreach my $design_id (keys %$summaries){
        my $gene_id = $gene_id_for_design->{$design_id};
        $result->{$gene_id}->{$design_id} = $summaries->{$design_id};
    }

    return $result;
}

sub get_crispr_summaries_for_designs{
	my ($self, $params) = @_;

    ref $params->{id_list} eq ref []
        or die "id_list must be an arrayref";

    my $result = {};
    my $design_id_for_crispr = {};

    my @crispr_id_list;
    DEBUG "Finding crisprs for designs";

    if($params->{find_all_crisprs}){
        # Fetch all crispr entities targetting the design
        # Not done by default as this is slow
        DEBUG "finding all crisprs targetting design";
        foreach my $design_id (@{ $params->{id_list} }){
            my $design = $self->c_retrieve_design({ id => $design_id });

            my ($crisprs, $pairs, $groups) = crisprs_for_design($self,$design);
            $result->{$design_id}->{all_crisprs} = $crisprs;
            $result->{$design_id}->{all_pairs} = $pairs;
            $result->{$design_id}->{all_groups} = $groups;
        }
    }

    my $experiment_rs = $self->schema->resultset('Experiment')->search(
        {
            design_id => { -in => $params->{id_list} }
        }
    );
    while (my $link = $experiment_rs->next){
        my @crispr_ids;

        if ($link->crispr_id){
            push @crispr_ids, $link->crispr_id;
        }
        elsif(my $pair = $link->crispr_pair){
            push @crispr_ids, $pair->left_crispr_id, $pair->right_crispr_id;
            # Store pairs of IDs
            $result->{$link->design_id}->{plated_pairs}->{$pair->id}->{left_id} = $pair->left_crispr_id;
            $result->{$link->design_id}->{plated_pairs}->{$pair->id}->{right_id} = $pair->right_crispr_id;
        }
        elsif(my $group = $link->crispr_group){
            my @group_crispr_ids = map { $_->crispr_id } $group->crispr_group_crisprs->all;
            push @crispr_ids, @group_crispr_ids;
            $result->{$link->design_id}{plated_groups}{$group->id} = \@group_crispr_ids;
        }

        foreach my $crispr_id (@crispr_ids){
            $design_id_for_crispr->{ $crispr_id } = $link->design_id;
            push @crispr_id_list, $crispr_id;
        }
    }
    DEBUG scalar(@crispr_id_list)." crisprs found";

    my $summaries = $self->get_summaries_for_crisprs({ id_list => \@crispr_id_list });

    # Store each summary under the correct design id
    foreach my $crispr_id (keys %$summaries){
    	my $design_id = $design_id_for_crispr->{$crispr_id};
    	$result->{$design_id}->{plated_crisprs}->{$crispr_id} = $summaries->{$crispr_id};
    }

    return $result;
}

sub get_summaries_for_crisprs{
	my ($self, $params) = @_;

    ref $params->{id_list} eq ref []
        or die "id_list must be an arrayref";

    my $result = {};
    my $crispr_id_for_well = {};
    my $date_for_well = {};

    my @crispr_well_id_list;

    DEBUG "Finding crispr wells";
    my $process_crispr_rs = $self->schema->resultset('ProcessCrispr')->search(
        { crispr_id => { '-in' => $params->{id_list} } },
        { prefetch => { process => 'process_output_wells'}}
    );

    while (my $process_crispr = $process_crispr_rs->next){
        my $crispr_id = $process_crispr->crispr_id;

        foreach my $output_well ($process_crispr->process->process_output_wells){
            # Store list of well IDs to fetch descendants from
            my $well_id = $output_well->well_id;
            $crispr_id_for_well->{ $well_id } = $crispr_id;
            $date_for_well->{ $well_id } = $output_well->well->created_at;
            push @crispr_well_id_list, $well_id;
        }
    }
    DEBUG scalar(@crispr_well_id_list)." Crispr wells found";

    my $summaries = $self->get_summaries_for_crispr_wells({ id_list => \@crispr_well_id_list });

    # Store each summary under correct crispr id
    foreach my $crispr_well_id (keys %$summaries){
        my $crispr_id = $crispr_id_for_well->{$crispr_well_id};
        $result->{$crispr_id}->{$crispr_well_id} = $summaries->{$crispr_well_id};
        $result->{$crispr_id}->{$crispr_well_id}->{crispr_well_created} = $date_for_well->{$crispr_well_id};
    }

    return $result;
}

sub get_summaries_for_crispr_wells{
    my ($self, $params) = @_;

    ref $params->{id_list} eq ref []
        or die "id_list must be an arrayref";

    my $child_well_id_lists = {};
    my $result = {};

    # return if id list is empty
    unless (scalar @{ $params->{id_list} }){
        DEBUG "Empty ID list passed to get_summaries_for_crispr_wells";
        return {};
    }

    # Get all crispr well descendants
    DEBUG "Running descendant query";
    my $paths = $self->get_descendants_for_well_id_list($params->{id_list});
    DEBUG "Descendant query done";

    # Store list of child well ids for each starting well
    foreach my $path (@$paths){
        my ($root, @children) = @{ $path->[0]  };
        $child_well_id_lists->{$root} ||= [];

        my $arrayref = $child_well_id_lists->{$root};
        push @$arrayref, @children;
    }

    my @plate_types = qw(CRISPR_V DNA ASSEMBLY);

    # Unique the list of well IDs and create resultsets
    foreach my $crispr_well_id (keys %$child_well_id_lists){
        my $child_wells = $child_well_id_lists->{$crispr_well_id};
        my $unique_well_ids = [ uniq @$child_wells ];
        foreach my $type (@plate_types){
            my $well_rs = $self->schema->resultset('Well')->search(
                {
                    'me.id' => { -in => $unique_well_ids },
                    'plate.type_id' => $type,
                },
                {
                    prefetch => ['plate']
                }
            );
            $result->{$crispr_well_id}->{$type} = $well_rs;
        }
        $result->{$crispr_well_id}->{child_well_id_list} = $unique_well_ids;
    }

    return $result;
}

sub get_crispr_wells_for_design {
    my ($self, $design_id) = @_;

    my $result = {};

    my @crispr_id_list;
    DEBUG "Finding crisprs for design";

    my $experiment_rs = $self->schema->resultset('Experiment')->search(
        {
            design_id => { -in => $design_id }
        }
    );
    while (my $link = $experiment_rs->next){
        my @crispr_ids;

        if ($link->crispr_id){
            push @crispr_ids, $link->crispr_id;
        }
        elsif(my $pair = $link->crispr_pair){
            push @crispr_ids, $pair->left_crispr_id, $pair->right_crispr_id;
            # Store pairs of IDs
            $result->{$link->design_id}->{plated_pairs}->{$pair->id}->{left_id} = $pair->left_crispr_id;
            $result->{$link->design_id}->{plated_pairs}->{$pair->id}->{right_id} = $pair->right_crispr_id;
        }
        elsif(my $group = $link->crispr_group){
            my @group_crispr_ids = map { $_->crispr_id } $group->crispr_group_crisprs->all;
            push @crispr_ids, @group_crispr_ids;
            $result->{$link->design_id}{plated_groups}{$group->id} = \@group_crispr_ids;
        }

        foreach my $crispr_id (@crispr_ids){
            push @crispr_id_list, $crispr_id;
        }
    }
    DEBUG scalar(@crispr_id_list)." crisprs found";


    my @crispr_well_list;

    DEBUG "Finding crispr wells";
    my $process_crispr_rs = $self->schema->resultset('ProcessCrispr')->search(
        { crispr_id => { '-in' => \@crispr_id_list } },
        { prefetch => { process => 'process_output_wells'}}
    );

    while (my $process_crispr = $process_crispr_rs->next){
        my $crispr_id = $process_crispr->crispr_id;

        foreach my $output_well ($process_crispr->process->process_output_wells){
            # Store list of wells
            my $well_id = $output_well->well_id;;
            push @crispr_well_list, $self->retrieve_well( { id => $well_id } );
        }
    }
    DEBUG scalar(@crispr_well_list)." Crispr wells found";

    return @crispr_well_list;
}

1;
