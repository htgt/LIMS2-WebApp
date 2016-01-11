package LIMS2::Model::Util::Crisprs;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::Crisprs::VERSION = '0.360';
}
## use critic

use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::Crisprs

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ 'crispr_pick', 'crisprs_for_design', 'gene_ids_for_crispr', 'get_crispr_group_by_crispr_ids' ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( none uniq );
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

    my $crispr_types = $request_params->{crispr_types};
    LIMS2::Exception->throw('No crispr_type set') unless $crispr_types;

    my $crispr_id_column;
    my ( $checked_design_crispr_links, $existing_design_crispr_links );
    if ( $crispr_types eq 'pair' ) {
        $checked_design_crispr_links = parse_request_param( $request_params, 'crispr_pair_pick' );
        $existing_design_crispr_links = parse_request_param( $request_params, 'design_crispr_pair_link' );
        $crispr_id_column = 'crispr_pair_id';
    }
    elsif ( $crispr_types eq 'single' ) {
        $checked_design_crispr_links = parse_request_param( $request_params, 'crispr_pick' );
        $existing_design_crispr_links = parse_request_param( $request_params, 'design_crispr_link' );
        $crispr_id_column = 'crispr_id';
    }
    elsif ( $crispr_types eq 'group' ){
        $checked_design_crispr_links = parse_request_param( $request_params, 'crispr_group_pick' );
        $existing_design_crispr_links = parse_request_param( $request_params, 'design_crispr_group_link' );
        $crispr_id_column = 'crispr_group_id';
    }
    else {
        LIMS2::Exception->throw("Unknown crispr type $crispr_types");
    }

    # find new crispr_design links to create
    my $create_links = compare_design_crispr_links( $checked_design_crispr_links,
        $existing_design_crispr_links, $crispr_id_column );

    # file existing crispr_design links to delete
    my $delete_links = compare_design_crispr_links( $existing_design_crispr_links,
        $checked_design_crispr_links, $crispr_id_column );

    my ( $create_log, $create_fail_log );
    if ( $crispr_types eq 'pair' ) {
        ( $create_log, $create_fail_log )
            = create_crispr_pair_design_links( $model, $create_links, $default_assembly );
    }
    elsif ( $crispr_types eq 'single' ) {
        ( $create_log, $create_fail_log )
            = create_crispr_design_links( $model, $create_links, $default_assembly );
    }
    elsif ( $crispr_types eq 'group' ){
        ( $create_log, $create_fail_log )
            = create_crispr_group_design_links( $model, $create_links, $default_assembly );
    }
    my ( $delete_log, $delete_fail_log ) = delete_crispr_design_links( $model, $delete_links );

    @logs{qw( create delete create_fail delete_fail )}
        = ( $create_log, $delete_log, $create_fail_log, $delete_fail_log );

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

We have two hashes, original and new, whose keys are design ids and values
hashes of crispr crispr_pair ids.

For each design id key in the original hash, find all the crispr ids in the
original hash that are not present in the new hash.

For each of these values store the crispr / crispr_pair id against the design
id and return a array of these.

=cut
sub compare_design_crispr_links {
    my ( $orig, $new, $crispr_id_type ) = @_;

    my @change_links;
    for my $design_id ( sort keys %{ $orig } ) {
        my $orig_links = $orig->{ $design_id };

        if ( my $new_links = $new->{ $design_id } ) {
            # we have both orig and new links, compare
            for my $crispr_id ( sort keys %{ $orig_links } ) {
                unless ( exists $new_links->{ $crispr_id } ) {
                    push @change_links,
                        { design_id => $design_id, $crispr_id_type => $crispr_id };
                }
            }
        }
        # no new links, change all specified links
        else {
            for my $crispr_id ( sort keys %{ $orig_links } ) {
                push @change_links,
                    { design_id => $design_id, $crispr_id_type => $crispr_id };
            }
        }
    }

    return \@change_links;
}

=head2 create_crispr_group_design_links

Create a link between a design and a crispr group after validating that the
crispr group and design hit the same location.

=cut
sub create_crispr_group_design_links {
    my ( $model, $create_links, $default_assembly ) = @_;
    my ( @create_log, @fail_log );

    for my $datum ( @{ $create_links } ) {
        my $design = $model->c_retrieve_design( { id => $datum->{design_id} } );
        my $crispr_group = $model->schema->resultset( 'CrisprGroup' )->find(
            { id => $datum->{crispr_group_id} },
            { prefetch => [ 'crispr_group_crisprs' ] },
        );
        LIMS2::Exception->throw( 'Can not find crispr group: ' . $datum->{crispr_group_id} )
            unless $crispr_group;

        next unless crispr_group_hits_design( $design, $crispr_group, $default_assembly, \@fail_log );

        my $crispr_design = $model->schema->resultset( 'CrisprDesign' )->find_or_create(
            {
                design_id      => $design->id,
                crispr_group_id => $crispr_group->id,
            }
        );
        INFO('Crispr design record created: ' . $crispr_design->id );

        push @create_log, 'Linked design & crispr group ' . p(%$datum);
    }

    return ( \@create_log, \@fail_log );
}

=head2 create_crispr_pair_design_links

Create a link between a design and a crispr pair after validating that the
crispr pair and design hit the same location.

=cut
sub create_crispr_pair_design_links {
    my ( $model, $create_links, $default_assembly ) = @_;
    my ( @create_log, @fail_log );

    for my $datum ( @{ $create_links } ) {
        my $design = $model->c_retrieve_design( { id => $datum->{design_id} } );
        my $crispr_pair = $model->schema->resultset( 'CrisprPair' )->find(
            { id => $datum->{crispr_pair_id} },
            { prefetch => [ 'left_crispr', 'right_crispr' ] },
        );
        LIMS2::Exception->throw( 'Can not find crispr pair: ' . $datum->{crispr_pair_id} )
            unless $crispr_pair;

        next unless crispr_pair_hits_design( $design, $crispr_pair, $default_assembly, \@fail_log );

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

=head2 create_crispr_design_links

Create a link between a design and a crispr after validating that the
crispr and design hit the same location.

=cut
sub create_crispr_design_links {
    my ( $model, $create_links, $default_assembly ) = @_;
    my ( @create_log, @fail_log );

    for my $datum ( @{ $create_links } ) {
        my $design = $model->c_retrieve_design( { id => $datum->{design_id} } );
        my $crispr = $model->schema->resultset( 'Crispr' )->find(
            { id => $datum->{crispr_id} },
            { prefetch => 'loci' },
        );
        LIMS2::Exception->throw( 'Can not find crispr: ' . $datum->{crispr_id} )
            unless $crispr;

        unless ( crispr_hits_design( $design, $crispr, $default_assembly ) ) {
            ERROR( 'Crispr does not hit same target as design : ' . p($datum) );
            push @fail_log,
                  'Additional validation failed between design & crispr ' . p(%$datum);
            next;
        }

        my $crispr_design = $model->schema->resultset( 'CrisprDesign' )->find_or_create(
            {
                design_id => $design->id,
                crispr_id => $crispr->id,
            }
        );
        INFO('Crispr design record created: ' . $crispr_design->id );
        push @create_log, 'Linked design & crispr ' . p(%$datum);
    }

    return ( \@create_log, \@fail_log );
}

=head2 delete_crispr_design_links

Delete a link between a crispr or crispr pair and a design.

=cut
sub delete_crispr_design_links {
    my ( $model, $delete_links ) = @_;
    my ( @delete_log, @fail_log );

    for my $datum ( @{ $delete_links } ) {
        my $crispr_design = $model->schema->resultset( 'CrisprDesign' )->find( $datum );
        unless ( $crispr_design ) {
            ERROR( 'Unable to find crispr_design link ' . p(%$datum) );
            push @fail_log, 'Failed to find design & crispr link: ' . p(%$datum);
            next;
        }
        if ( $crispr_design->delete ) {
            INFO( 'Deleted crispr_design record ' . $crispr_design->id );
            push @delete_log, 'Deleted link between design & crispr: ' . p(%$datum);
        }
        else {
            ERROR( 'Failed to delete crispr_design record ' . $crispr_design->id );
            push @fail_log, 'Failed to delete design & crisprlink ' . p(%$datum);
        }
    }

    return ( \@delete_log, \@fail_log );
}

=head2 crispr_group_hits_design

Check that the crispr group's crispr locations match with the design target region.

=cut
sub crispr_group_hits_design {
    my ( $design, $crispr_group, $default_assembly, $fail_log ) = @_;

    my $design_info = LIMS2::Model::Util::DesignInfo->new(
        design           => $design,
        default_assembly => $default_assembly,
    );

    # FIXME: is this correct? group hits design if one or more crisprs hit design
    my $crispr_hits_design = 0;
    foreach my $crispr ($crispr_group->crisprs){
        if ( crispr_hits_design( $design, $crispr, $default_assembly, $design_info ) ){
            $crispr_hits_design = 1;
        }
    }
    unless ($crispr_hits_design)
    {
        ERROR( 'Crispr Group ' . $crispr_group->id . ' does not hit design ' . $design->id );
        push @{$fail_log},
              'Additional validation failed between design: ' . $design->id
            . ' & crispr group: ' . $crispr_group->id
            . ', no crispr in the group lies wholly within target region of design';
        return 0;
    }

    return 1;
}

=head2 crispr_pair_hits_design

Check that the crispr pairs 2 crisprs location matches with the designs target region.

=cut
sub crispr_pair_hits_design {
    my ( $design, $crispr_pair, $default_assembly, $fail_log ) = @_;

    my $design_info = LIMS2::Model::Util::DesignInfo->new(
        design           => $design,
        default_assembly => $default_assembly,
    );

    if (
        !crispr_hits_design( $design, $crispr_pair->left_crispr, $default_assembly, $design_info ) &&
        !crispr_hits_design( $design, $crispr_pair->right_crispr, $default_assembly, $design_info )
    )
    {
        ERROR( 'Crispr Pair ' . $crispr_pair->id . ' does not hit design ' . $design->id );
        push @{$fail_log},
              'Additional validation failed between design: ' . $design->id
            . ' & crispr pair: ' . $crispr_pair->id
            . ', neither crispr lies wholly within target region of design';
        return 0;
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

=head2 crisprs_for_design

Find all crisprs that intersect with a given design

=cut
sub crisprs_for_design {
    my ( $model, $design ) = @_;

    my $design_info = LIMS2::Model::Util::DesignInfo->new(
        design => $design,
    );

    my $chr_id = $model->_chr_id_for( $design_info->default_assembly, $design_info->chr_name );
    my @crisprs = $model->schema->resultset('Crispr')->search(
        {
            'loci.assembly_id' => $design_info->default_assembly,
            'loci.chr_id'      => $chr_id,
            'loci.chr_start'   => { '>' => $design_info->target_region_start - 50 },
            'loci.chr_end'     => { '<' => $design_info->target_region_end + 50 },
        },
        {
            join => 'loci',
        }
    );

    my ( @left_crispr_ids, @right_crispr_ids );
    for my $crispr ( @crisprs ) {
        my $direction = $crispr->pam_right;
        # if undef crispr does not have a stored direction and is not part of a pair
        next unless defined $direction;
        if ( $direction == 1 ) {
            push @right_crispr_ids, $crispr->id;
        }
        elsif ( $direction == 0 ) {
            push @left_crispr_ids, $crispr->id;
        }

    }

    my @crispr_pairs = $model->schema->resultset( 'CrisprPair' )->search(
        {
            left_crispr_id  => { 'IN' => \@left_crispr_ids },
            right_crispr_id => { 'IN' => \@right_crispr_ids },
        }
    );

    my @crispr_groups = $model->schema->resultset( 'CrisprGroup' )->search(
        {
            'crispr_group_crisprs.crispr_id' => { 'IN' => \@crisprs },
        },
        {
            join => 'crispr_group_crisprs',
            distinct => 1,
        }
    );

    return ( \@crisprs, \@crispr_pairs, \@crispr_groups );
}

=head2 gene_ids_for_crispr

Return gene ids linked to a crispr

gene finder should be a coderef pointing to a method that finds genes.
usually this will be sub { $c->model('Golgi')->find_genes( @_ ) }

=cut
sub gene_ids_for_crispr {
    my ( $gene_finder, $crispr ) = @_;
    my @gene_ids;

    if ( $crispr->is_group ) {
        push @gene_ids, $crispr->gene_id;
    }
    # method on both crispr and crispr pair that looks at linked designs
    elsif ( my @designs = $crispr->related_designs ) {
        my @design_gene_ids = map{ $_->genes->first->gene_id } @designs;
        push @gene_ids, uniq @design_gene_ids;
    }
    else {
        # now we have a crispr or crispr pair and no linked designs, need to look at sequence
        my $slice = try{ $crispr->target_slice };
        return [] unless $slice;
        my @genes = @{ $slice->get_all_Genes };

        my @gene_names = map{ $_->display_id } @genes;
        @gene_ids = map { $_->{gene_id} }
                      values %{ $gene_finder->( $crispr->species_id, \@gene_names ) };
    }

    return \@gene_ids;
}

=head2 get_crispr_group_by_crispr_ids

Given a list of crispr IDs find a crispr group that contains all of them.
Check all crisprs in this group are in the list provided.
This method is needed in case we end up with crisprs belonging to multiple
crispr groups, or different sized groups containing subsets of other groups,
and other possible situations for which the simple search query is not enough
to identify the correct group.

=cut
sub get_crispr_group_by_crispr_ids{
    my ($schema, $params) = @_;
    my @crispr_ids = @{ $params->{crispr_ids} }
        or die "No crispr_ids array provided to get_crispr_group_by_crispr_ids";

    my @crispr_groups = $schema->resultset('CrisprGroup')->search(
        {
            'crispr_group_crisprs.crispr_id' => { 'IN' => \@crispr_ids },
        },
        {
            join     => 'crispr_group_crisprs',
            distinct => 1,
        }
    )->all;

    my %input_ids = map { $_ => 1 } @crispr_ids;
    DEBUG('input IDs: '.(join ",",@crispr_ids));
    my $error_msg = "No crispr group found for crispr IDs ".(join ",",@crispr_ids).". ";

    foreach my $group (@crispr_groups){
        my $group_id = $group->id;
        DEBUG('Comparing crispr group '.$group->id.' to crispr ID list');
        my @group_crispr_ids = map { $_->crispr_id } $group->crispr_group_crisprs;
        my %group_ids = map { $_ => 1 } @group_crispr_ids;

        # See if any input crispr IDs are not in the group
        my @inputs_not_in_group = grep { !$group_ids{$_} } @crispr_ids;

        # See if any group crispr IDs are not in the input list
        my @group_ids_not_in_input = grep { !$input_ids{$_} } @group_crispr_ids;

        if(@inputs_not_in_group == 0 and @group_ids_not_in_input == 0){
            # This is the right group so return it
            return $group;
        }
        else{
            # Generate some error messages
            if( @inputs_not_in_group ){
               $error_msg .= "Group $group_id does not contain these crispr IDs which were in the input list: "
                             .(join ",", @inputs_not_in_group).". ";
            }

            if (@group_ids_not_in_input){
                $error_msg .= "Group $group_id contains these crispr IDs which were not in the input list: "
                              .(join ",", @group_ids_not_in_input).". ";
            }
        }
    }
    LIMS2::Exception->throw($error_msg);
    return;
}

1;
