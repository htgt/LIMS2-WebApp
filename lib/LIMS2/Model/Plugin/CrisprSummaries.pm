package LIMS2::Model::Plugin::CrisprSummaries;

use Moose::Role;
use LIMS2::Model;
use LIMS2::Model::Util::Crisprs qw( crisprs_for_design );
use List::MoreUtils qw( uniq );

use strict;
use warnings;

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
    plated_crisprs
      <crispr id>
        CRISPR_array
          [ crispr wells ]
        crispr_well_id_list
          [ well ids ]
        <crispr well id>
          CRISPR_V
            [ well resultset ]
          DNA
            [ well resultset ]
          child_well_id_list
            [ well ids ]

FIXME: should probably wrap this data structure in a Moose Class

=cut

sub get_crispr_summaries_for_genes{
    my ($self, $params) = @_;

    ref $params->{id_list} eq ref []
        or die "id_list must be an arrayref";
}

sub get_crispr_summaries_for_designs{
	my ($self, $params) = @_;

    ref $params->{id_list} eq ref []
        or die "id_list must be an arrayref";

    my $result = {};
    my $design_id_for_crispr = {};

    my @crispr_id_list;
    foreach my $design_id (@{ $params->{id_list} }){
        
        my $design = $self->c_retrieve_design({ id => $design_id });

        # Fetch all crisprs and pairs targetting the design
        my ($crisprs, $pairs) = crisprs_for_design($self,$design);

        $result->{$design_id}->{all_crisprs} = $crisprs;
        $result->{$design_id}->{all_pairs} = $pairs;

        # Preserve crispr to design connection here and add crisp id to list
        # We have to do this so that we can do a single well descend query
        # and then organise the summary results by design id afterwards
        foreach my $crispr (@$crisprs){
        	$design_id_for_crispr->{ $crispr->id } = $design_id;
        	push @crispr_id_list, $crispr->id;
        }
    }

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

    my @crispr_well_id_list;

    my $process_crispr_rs = $self->schema->resultset('ProcessCrispr')->search(
        { crispr_id => { '-in' => $params->{id_list} } },
    );

    while (my $process_crispr = $process_crispr_rs->next){
        my $crispr_id = $process_crispr->crispr_id;

        unless (exists $result->{$crispr_id}->{crispr_well_id_list} ){
            $result->{$crispr_id}->{crispr_well_id_list} = [];
        }
        my $well_id_list = $result->{$crispr_id}->{crispr_well_id_list};

        unless (exists $result->{$crispr_id}->{CRISPR_array} ){
            $result->{$crispr_id}->{CRISPR_array} = [];
        }
        my $crispr_well_array = $result->{$crispr_id}->{CRISPR_array};

        foreach my $well ($process_crispr->process->output_wells){
            # Store list of well IDs to fetch descendants from
            $crispr_id_for_well->{ $well->id } = $crispr_id;
            push @crispr_well_id_list, $well->id;
            # Store wells and IDs by crispr
            push @$well_id_list, $well->id;
            push @$crispr_well_array, $well;
        }
    }

    my $summaries = $self->get_summaries_for_crispr_wells({ id_list => \@crispr_well_id_list });
    
    # Store each summary under correct crispr id
    foreach my $crispr_well_id (keys %$summaries){
        my $crispr_id = $crispr_id_for_well->{$crispr_well_id};
        $result->{$crispr_id}->{$crispr_well_id} = $summaries->{$crispr_well_id};
    }

    return $result;
}

sub get_summaries_for_crispr_wells{
    my ($self, $params) = @_;

    ref $params->{id_list} eq ref []
        or die "id_list must be an arrayref";

    my $child_well_id_lists = {};
    my $result = {};

    # Get all crispr well descendants
    my $paths = $self->get_descendants_for_well_id_list($params->{id_list});

    # Store list of child well ids for each starting well
    foreach my $path (@$paths){
        my ($root, @children) = @{ $path->[0]  };
        unless(exists $child_well_id_lists->{$root}){
            $child_well_id_lists->{$root} = [];
        }
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

1;