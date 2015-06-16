package LIMS2::Model::Util::DesignTargets;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::DesignTargets::VERSION = '0.323';
}
## use critic

use strict;
use warnings FATAL => 'all';


=head1 NAME

LIMS2::Model::Util::DesignTargets

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw( designs_matching_design_target_via_exon_name
                     designs_matching_design_target_via_coordinates
                     crisprs_for_design_target
                     find_design_targets
                     design_target_report_for_genes
                     bulk_designs_for_design_targets
                     get_design_targets_data
                     prebuild_oligos
                     target_overlaps_exon
                    ) ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( any );
use LIMS2::Exception;
use LIMS2::Model::Util::DesignInfo;
use Try::Tiny;
use YAML::Any;
use List::Util qw( first );

=head2 designs_matching_design_target_via_exon_name

For a given design target retrieve any designs that match the design target exon / gene.

First select the designs with the same gene as the design target.
NOTE: The gene names much match exactly, if they do not the design will not be considered.
So it is possible there will be designs that hit the target but do not show up because of
a mismatch in or missing design gene information.

Each of the designs with matching gene targets are then checked to see if they hit the target exon and
a list of these designs is returned.
NOTE: A partial hit on the target exon counts here.

=cut
sub designs_matching_design_target_via_exon_name {
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

=head2 designs_matching_design_target_via_coordinates

For a given design target retrieve any designs that match the design target exon / gene.

First select the designs with the same gene as the design target.
NOTE: The gene names much match exactly, if they do not the design will not be considered.
So it is possible there will be designs that hit the target but do not show up because of
a mismatch in or missing design gene information.

Each of the designs with matching gene targets are then checked to see if their target region
encompasses the target exons start and end coordinates.
a list of these designs is returned.

NOTE: Will not find designs with partial hits target exon

=cut
sub designs_matching_design_target_via_coordinates {
    my ( $schema, $design_target ) = @_;
    my @matching_designs;

    my @designs = $schema->resultset('Design')->search(
        {
            'genes.gene_id' => $design_target->gene_id,
            species_id      => $design_target->species_id,
        },
        {
            join => 'genes',
        },
    );

    for my $design ( @designs ) {
        if ( $design_target->chr_start > $design->target_region_start
            && $design_target->chr_end < $design->target_region_end
        ) {
            push @matching_designs, $design;
        }
    }

    return \@matching_designs;
}

=head2 bulk_designs_for_design_targets

Bulk lookup of designs for multiple design targets, to speed things up, must specify species_id

=cut
sub bulk_designs_for_design_targets {
    my ( $schema, $design_targets, $species_id, $assembly ) = @_;

    my @gene_designs = $schema->resultset('GeneDesign')->search(
        {
            -and => [
                gene_id => { 'IN' => [ map{ $_->gene_id } @{ $design_targets } ] },
                'design.species_id'     => $species_id,
                -or => [
                    'design.design_type_id' => 'gibson',
                    'design.design_type_id' => 'gibson-deletion',
                ],
            ],
        },
        {
            join     => 'design',
            prefetch => { 'design' => { 'oligos' => { 'loci' => 'chr' } } },
        },
    );

    my %data;
    my @design_ids;
    for my $dt ( @{ $design_targets } ) {
        my @matching_designs;
        my @dt_designs = map{ $_->design } grep{ $_->gene_id eq $dt->gene_id } @gene_designs;
        #TODO refactor, we are working out same design coordinates multiple times sp12 Mon 24 Feb 2014 13:20:23 GMT
        for my $design ( @dt_designs ) {
            my $oligo_data = prebuild_oligos( $design, $assembly );
            # if no oligo data then design does not have oligos on assembly
            next unless $oligo_data;
            my $di = LIMS2::Model::Util::DesignInfo->new(
                design           => $design,
                default_assembly => $assembly,
                oligos           => $oligo_data,
            );
            next if $dt->chr->name ne $di->chr_name;

            if (target_overlaps_exon(
                    $di->target_region_start, $di->target_region_end, $dt->chr_start, $dt->chr_end )
                )
            {
                push @matching_designs, $design;
                push @design_ids, $design->id;
            }
        }
        $data{ $dt->id } = \@matching_designs;
    }

    my $design_crispr_links = fetch_existing_design_crispr_links( $schema, \@design_ids );

    return ( \%data, $design_crispr_links );
}

=head2 fetch_existing_design_crispr_links

Find all the pre-existing links between the designs and crisprs
for a list of designs.

=cut
sub fetch_existing_design_crispr_links {
    my ( $schema, $design_ids ) = @_;
    my %design_crispr_links;

    my @crispr_designs = $schema->resultset( 'CrisprDesign' )->search(
        {
            design_id => { 'IN' => $design_ids },
        },
        {
            prefetch => 'crispr_pair',
        }
    );

    # there is nothing stopping a record having a link to both a crispr_id and
    # a crispr_pair_id so check for both
    # and now check for crispr_group_id too
    for my $crispr_design ( @crispr_designs ) {
        # if we have a single crispr linked to a design store that id
        if ( $crispr_design->crispr_id ) {
            push @{ $design_crispr_links{ $crispr_design->design_id }{single} }, $crispr_design->crispr_id;
        }

        # if we have a crispr pair linked to a design store both ids
        if ( $crispr_design->crispr_pair_id ) {
            push @{ $design_crispr_links{ $crispr_design->design_id }{pair} },
                $crispr_design->crispr_pair_id;
            #my $crispr_pair = $crispr_design->crispr_pair;
            #push @{ $design_crispr_links{ $crispr_design->design_id } }, (
                #$crispr_pair->left_crispr_id,
                #$crispr_pair->right_crispr_id,
            #);
        }

        if ( $crispr_design->crispr_group_id ) {
            push @{ $design_crispr_links{ $crispr_design->design_id }{group} },
                $crispr_design->crispr_group_id;
        }
    }

    #TODO uniq the list of crisprs? sp12 Fri 18 Oct 2013 08:12:53 BST

    return \%design_crispr_links;
}

=head2 prebuild_oligos

Pre-build oligo hash for design from pre-fetched data to feed into design info object.
This stops the design info object making its own database queries and speeds up the
overall data retrieval.

=cut
sub prebuild_oligos {
    my ( $design, $default_assembly ) = @_;

    my %design_oligos_data;
    for my $oligo ( $design->oligos ) {
        my ( $locus ) = grep{ $_->assembly_id eq $default_assembly } $oligo->loci;
        return unless $locus;

        my %oligo_data = (
            start      => $locus->chr_start,
            end        => $locus->chr_end,
            chromosome => $locus->chr->name,
            strand     => $locus->chr_strand,
        );
        $oligo_data{seq} = $oligo->seq;

        $design_oligos_data{ $oligo->design_oligo_type_id } = \%oligo_data;
    }

    return \%design_oligos_data;
}

=head2 crisprs_for_design_target

Find crisprs that match to a given design target

=cut
sub crisprs_for_design_target {
    my ( $schema, $design_target ) = @_;

    my @crisprs = $schema->resultset('Crispr')->search(
        {
            'loci.assembly_id' => $design_target->assembly_id,
            'loci.chr_id'      => $design_target->chr_id,
            'loci.chr_start'   => { '>' => $design_target->chr_start - 200 },
            'loci.chr_end'     => { '<' => $design_target->chr_end + 200 },
        },
        {
            join     => 'loci',
            prefetch => 'off_target_summaries',
        }
    );

    return \@crisprs;
}

=head2 bulk_crisprs_for_design_targets

Using the custom DesignTargetCrisprs view find all the crisprs for a set of
design targets.

=cut
sub bulk_crisprs_for_design_targets {
    my ( $schema, $design_targets, $off_target_algorithm  ) = @_;

    my @dt_crisprs = $schema->resultset('DesignTargetCrisprs')->search(
        {
            design_target_id => { 'IN' => [ map{ $_->id } @{ $design_targets } ] },
            'off_target_summaries.algorithm' => $off_target_algorithm,
        },
        {
            prefetch => { 'crispr' => 'off_target_summaries' },
        },
    );

    my %crisprs;
    for my $dt ( @{ $design_targets } ) {
        my %matching_crisprs = map { $_->crispr_id => $_->crispr }
            grep { $_->design_target_id eq $dt->id } @dt_crisprs;
        $crisprs{ $dt->id } = \%matching_crisprs;
    }

    my %crispr_pairs;
    my %crispr_groups;
    for my $dt_id ( keys %crisprs ) {
        my @left_crisprs  = map{ $_->id } grep{ !$_->pam_right } values %{ $crisprs{ $dt_id } };
        my @right_crisprs = map { $_->id } grep{ $_->pam_right } values %{ $crisprs{ $dt_id } };

        my @crispr_pairs = $schema->resultset( 'CrisprPair' )->search(
            {
                left_crispr_id  => { 'IN' => \@left_crisprs },
                right_crispr_id => { 'IN' => \@right_crisprs },
            }
        );
        $crispr_pairs{ $dt_id } = { map{ $_->id => $_ } @crispr_pairs };

        my @crisprs = map { $_->id } values %{ $crisprs{ $dt_id } };
        # Find any groups containing a crispr for the design target
        # Should we check all the crisprs in the group are for this design target??
        my @groups = $schema->resultset( 'CrisprGroup' )->search(
            {
                'crispr_group_crisprs.crispr_id' => { 'IN' => \@crisprs },
            },
            {
                join => 'crispr_group_crisprs',
                distinct => 1,
            }
        );
        $crispr_groups{ $dt_id } = { map{ $_->id => $_ } @groups };
        DEBUG("Crispr groups for $dt_id:".join ",", map{ $_->id } @groups );
    }

    return ( \%crisprs, \%crispr_pairs, \%crispr_groups );
}

=head2 find_design_targets

Given a list of gene identifiers find any design targets

=cut
sub find_design_targets {
    my ( $schema, $sorted_genes, $species_id, $assembly, $build ) = @_;

    my @design_targets = $schema->resultset('DesignTarget')->search(
        {
            -or => [
                gene_id                   => { 'IN' => $sorted_genes->{gene_ids}  },
                'lower(me.marker_symbol)' => { 'IN' => $sorted_genes->{marker_symbols} },
                ensembl_gene_id           => { 'IN' => $sorted_genes->{ensembl_gene_ids} },
            ],
            'me.species_id'  => $species_id,
            'me.assembly_id' => $assembly,
            'me.build_id'    => $build,
        },
        {
            order_by => [ { -asc => 'gene_id' }, { -asc => 'exon_rank' } ],
            distinct => 1,
            prefetch => 'chr',
        }
    );

    return \@design_targets;
}

=head2 design_target_report_for_genes

Build up report data giving following information for specific gene targest:
Design Targets
Designs
Crisprs

=cut
sub design_target_report_for_genes {
    my ( $schema, $genes, $species_id, $build, $report_parameters ) = @_;

    my $assembly = $schema->resultset('SpeciesDefaultAssembly')->find(
        { species_id => $species_id } )->assembly_id;

    my $sorted_genes = _sort_gene_ids( $genes );
    my $design_targets = find_design_targets( $schema, $sorted_genes, $species_id, $assembly, $build );
    my ( $design_data, $design_crispr_links )
        = bulk_designs_for_design_targets( $schema, $design_targets, $species_id, $assembly );
    my ( $crispr_data, $crispr_pair_data, $crispr_group_data ) = bulk_crisprs_for_design_targets(
        $schema,
        $design_targets,
        $report_parameters->{off_target_algorithm},
    );

    #TODO gather crispr and design wells sp12 Tue 22 Oct 2013 08:14:19 BST

    my @report_data;
    for my $dt ( @{ $design_targets } ) {
        my %data;

        $data{'design_target'} = $dt;
        $data{'designs'} = $design_data->{ $dt->id };
        $data{'crisprs'} = $crispr_data->{ $dt->id };
        $data{'crispr_pairs'} = $crispr_pair_data->{ $dt->id };
        $data{'crispr_groups'} = $crispr_group_data->{ $dt->id };

        push @report_data, \%data;
    }

    my $formated_report_data = format_report_data(
        \@report_data,
        $design_crispr_links,
        $report_parameters,
        $assembly,
    );
    return( $formated_report_data, $sorted_genes );
}

=head2 format_report_data

Manipulate data into format we can easily display in a spreadsheet

=cut
sub format_report_data {
    my ( $data, $design_crispr_links, $report_parameters, $default_assembly ) = @_;
    my @report_row_data;

    for my $datum ( @{ $data } ) {
        my $design_target_data = _format_design_target_data( $datum->{design_target} );

        if ( $report_parameters->{type} eq 'simple' ) {
            $design_target_data->{designs} = scalar( @{ $datum->{designs} } );
            $design_target_data->{crisprs} = scalar( keys %{ $datum->{crisprs} } );
            $design_target_data->{crispr_pairs} = scalar( keys %{ $datum->{crispr_pairs} } );
            $design_target_data->{crispr_groups} = scalar( keys %{ $datum->{crispr_groups} } );
        }
        else {
            my ( $crispr_data, $display_crispr_num )
                = format_crispr_data( $datum, $report_parameters, $default_assembly );
            $design_target_data->{crisprs} = $crispr_data;

            my ( $design_data, $display_design_num )
                = format_design_data( $datum, $report_parameters, $design_crispr_links );
            $design_target_data->{designs} = $design_data;

            # work out rowspan attributes for design target and design section of report
            $design_target_data->{dt_rowspan} = ( $display_crispr_num ? $display_crispr_num : 1 )
                * ( $display_design_num ? $display_design_num : 1 );
            $design_target_data->{design_rowspan} = $display_crispr_num ? $display_crispr_num : 1;
        }

        push @report_row_data, $design_target_data;
    }

    return \@report_row_data;
}

=head2 _format_design_target_data

Format the design target data into something we can show in the report

=cut
sub _format_design_target_data {
    my ( $design_target ) = @_;

    my $ensembl_gene_link;
    if ( $design_target->species_id eq 'Human' ) {
        $ensembl_gene_link = 'http://www.ensembl.org/Homo_sapiens/Gene/Summary?g='
            . $design_target->ensembl_gene_id;
    }
    elsif ( $design_target->species_id eq 'Mouse' ) {
        $ensembl_gene_link = 'http://www.ensembl.org/Mus_musculus/Gene/Summary?g='
            . $design_target->ensembl_gene_id;
    }

    my %design_target_data = (
      design_target_id  => $design_target->id,
      marker_symbol     => $design_target->marker_symbol,
      gene_id           => $design_target->gene_id,
      ensembl_exon_id   => $design_target->ensembl_exon_id,
      ensembl_gene_id   => $design_target->ensembl_gene_id,
      exon_size         => $design_target->exon_size,
      exon_rank         => $design_target->exon_rank,
      chromosome        => $design_target->chr->name,
      ensembl_gene_link => $ensembl_gene_link,
    );

    return \%design_target_data;
}

=head2 format_crispr_data

Format the crispr / crispr pair data.

=cut
sub format_crispr_data {
    my ( $datum, $report_parameters, $default_assembly ) = @_;

    my $crispr_data;
    if ( $report_parameters->{crispr_types} eq 'single' ) {
        $crispr_data = _format_crispr_data(
            $datum->{crisprs},
            $report_parameters->{off_target_algorithm},
            $default_assembly
        );
    }
    elsif ( $report_parameters->{crispr_types} eq 'pair' ) {
        $crispr_data = _format_crispr_pair_data(
            $datum->{crispr_pairs},
            $datum->{crisprs},
            $report_parameters->{off_target_algorithm},
            $default_assembly,
            $report_parameters->{filter}
        );
    }
    elsif ( $report_parameters->{crispr_types} eq 'group' ){
        $crispr_data = _format_crispr_group_data(
            $datum->{crispr_groups},
            $datum->{crisprs},
            $report_parameters->{off_target_algorithm},
            $default_assembly,
        );
    }
    else {
        LIMS2::Exception->throw( 'Unknown crispr type: ' . $report_parameters->{crispr_type} );
    }
    my $display_crispr_num = scalar( @{ $crispr_data } );

    return ( $crispr_data, $display_crispr_num );
}

=head2 _format_crispr_data

Format the crispr data, add information about crisprs presense on Crispr plates.

=cut
sub _format_crispr_data {
    my ( $crisprs, $off_target_algorithm, $default_assembly ) = @_;
    my @crispr_data;
    $off_target_algorithm ||= 'strict';

    my @ranked_crisprs = sort {
        _rank_crisprs( $a, $off_target_algorithm ) <=> _rank_crisprs( $b, $off_target_algorithm )
    } values %{ $crisprs };

    for my $c ( @ranked_crisprs ) {
        # Blame ah19 for this unholy mess, b/c he gave undef a meaning in a
        # booleon field ( to be fair he didn't intend for this to happen )
        my $crispr_direction;
        if ( defined $c->pam_right ) {
            if ( $c->pam_right == 1 ) {
                $crispr_direction = 'right';
            }
            else {
                $crispr_direction = 'left';
            }
        }
        else {
            $crispr_direction = 'right';
        }
        my %data = (
            crispr_id => $c->id,
            wge_id    => $c->wge_crispr_id,
            seq       => $c->seq,
            blat_seq  => '>' . $c->id . "\n" . $c->seq,
            direction => $crispr_direction,
            locus     => _formated_crispr_locus( $c, $default_assembly ),
        );
        for my $summary ( $c->off_target_summaries->all ) {
            next unless $summary->algorithm eq $off_target_algorithm;
            my $valid = $summary->outlier ? 'no' : 'yes';
            $data{outlier} = $valid;
            $data{summary} = Load( $summary->summary );
            last;
        }

        #TODO add back crispr well information? sp12 Fri 25 Oct 2013 12:54:04 BST
        #my @process_crisprs = $c->process_crisprs->all;
        #unless ( @process_crisprs ) {
            #push @crispr_data, \%data;
            #next;
        #}

        #my @crispr_well_data;
        #for my $crispr_process ( @process_crisprs ) {
            #my $process_output_well = $crispr_process->process->process_output_wells->first;
            #next unless $process_output_well;
            #my $crispr_well = $process_output_well->well;
            #push @crispr_well_data, "$crispr_well";
        #}
        #$data{crispr_wells} = join( ',', @crispr_well_data );
        push @crispr_data, \%data;
    }

    return \@crispr_data;
}

=head2 _format_crispr_pair_data

Format the crispr pair data.
Get the first 5 pairs ( ranked according to _rank_crisp_pair )

=cut
sub _format_crispr_pair_data {
    my ( $crispr_pairs, $crisprs, $off_target_algorithm, $default_assembly , $filter) = @_;
    my @crispr_data;
    $off_target_algorithm ||= 'strict';

    my @valid_ranked_crispr_pairs;
    if ($filter) {
        @valid_ranked_crispr_pairs = sort { _rank_crispr_pairs($a) <=> _rank_crispr_pairs($b) }
            grep { _valid_crispr_pair($_) } values %{$crispr_pairs};
    } else {
        @valid_ranked_crispr_pairs = sort { _rank_crispr_pairs($a) <=> _rank_crispr_pairs($b) }
            grep { $_ } values %{$crispr_pairs};
    }

    for my $c ( @valid_ranked_crispr_pairs ) {
        my $left_crispr = $crisprs->{ $c->left_crispr_id };
        my $right_crispr = $crisprs->{ $c->right_crispr_id };

        my %data = (
            crispr_pair_id     => $c->id,
            left_crispr_id     => $left_crispr->id,
            left_crispr_wge_id => $left_crispr->wge_crispr_id,
            left_crispr_seq    => $left_crispr->seq,
            left_crispr_locus  => _formated_crispr_locus( $left_crispr, $default_assembly ),
            right_crispr_id    => $right_crispr->id,
            right_crispr_wge_id => $right_crispr->wge_crispr_id,
            right_crispr_seq   => $right_crispr->seq,
            right_crispr_locus => _formated_crispr_locus( $right_crispr, $default_assembly ),
            spacer             => $c->spacer,
            pair_off_target    => _format_crispr_pair_off_target_summary( $c ),
            left_off_target    => _format_crispr_off_target_summary( $left_crispr, $off_target_algorithm ),
            right_off_target   => _format_crispr_off_target_summary( $right_crispr, $off_target_algorithm ),
        );

        #TODO crispr well data??
        push @crispr_data, \%data;
    }

    return \@crispr_data;
}

=head2 _format_crispr_group_data

Format the crispr group data for report.

=cut
sub _format_crispr_group_data {
    my ( $crispr_groups, $crisprs, $off_target_algorithm, $default_assembly) = @_;
    my @crispr_data;
    $off_target_algorithm ||= 'strict';

    my @crispr_groups = grep { $_ } values %{$crispr_groups};

    for my $group ( @crispr_groups ) {
        my $h = $group->as_hash;
        my @crispr_details;

        for my $crispr ($group->crisprs){
            DEBUG("Getting details for group crispr ".$crispr->id);
            my $details = {
                crispr_id  => $crispr->id,
                wge_id     => $crispr->wge_crispr_id,
                seq        => $crispr->seq,
                locus      => _formated_crispr_locus($crispr, $default_assembly),
                off_target => _format_crispr_off_target_summary($crispr, $off_target_algorithm),
            };
            push @crispr_details, $details;
        }
=head

                off_target => _format_crispr_off_target_summary($crispr, $off_target_algorithm),
=cut
        $h->{crispr_details} = [ sort { $a->{crispr_id} <=> $b->{crispr_id} } @crispr_details ];
        push @crispr_data, $h;
    }

    return \@crispr_data;
}

=head2 format_design_data

Format design data to show in reports.
Also grab pre-existing link information between a design and a crispr / crispr pair,
this is so we can tick the checkboxes in the report where needed.

=cut
sub format_design_data {
    my ( $datum, $report_parameters, $design_crispr_links ) = @_;
    my @design_data;
    my $crispr_types = $report_parameters->{crispr_types};

    for my $design ( @{ $datum->{designs} } ) {
        my %data = (
            design_id   => $design->id,
            design_type => $design->design_type_id,
        );

        if ( exists $design_crispr_links->{ $design->id }{ $crispr_types } ) {
            $data{linked_crispr_ids} = $design_crispr_links->{ $design->id }{ $crispr_types };
        }

        push @design_data, \%data;
    }
    my $display_design_num = scalar( @design_data );

    return ( \@design_data, $display_design_num );
}

=head2 _rank_crisprs

Sort crisprs by off target hits.
The ranking depends on the off target algorithm used.
The lower the score the better.

=cut
sub _rank_crisprs {
    my ( $crispr, $off_target_algorithm ) = @_;
    my $score = 0;

    my $off_target_summary = first{ $_->algorithm eq $off_target_algorithm } $crispr->off_target_summaries->all;
    # check this, not sure it will work properly if sorting on weak algorithm
    return 5000 unless $off_target_summary;

    $score += 1000 if $off_target_summary->outlier;
    my $summary = Load($off_target_summary->summary);

    if ( $off_target_algorithm eq 'strict' ) {
        return $score + ( ($summary->{Exons} * 100) + ($summary->{Introns} * 10) + $summary->{Intergenic} );
    }
    elsif ( $off_target_algorithm eq 'bwa' ) {
        my %multiplier = ( 0 => 1000, 1 => 500, 2 => 300, 3 => 200, 4 => 100, 5 => 10, 6 => 1 );
        for my $num_mismatch ( keys %{ $summary } ) {
            if ( my $num_hits = $summary->{$num_mismatch} ) {
                $score += $num_hits * $multiplier{ $num_mismatch };
            }
        }
    }

    return $score;
}

=head2 _rank_crispr_pairs

Sort crispr pairs by:
* spacer, the closer to 20 the better
* then on off target pair distance ( the larger the better )

The lower the score the better

=cut
sub _rank_crispr_pairs {
    my ( $crispr_pair ) = @_;

    my $score = abs( 20 - $crispr_pair->spacer );

    # return a really bad score if there is no off target information
    my $ot_pair_distance;
    if ( $crispr_pair->off_target_summary ) {
        my $summary = Load($crispr_pair->off_target_summary);
        if ( my $distance = $summary->{distance} ) {
            $distance =~ s/\+//;
            # max distance currently 9000
            $ot_pair_distance = $distance / 10000;
        }
        else {
            $ot_pair_distance = 0.0001;
        }
    }
    else {
        $ot_pair_distance = 0.0001;
    }

    return $score - $ot_pair_distance;
}

=head2 _valid_crispr_pair

A crispr pair is invalid if the distance between its 'worst' off target
pair is less than 105 bases.

=cut
sub _valid_crispr_pair {
    my ( $crispr_pair  ) = @_;

    if ( $crispr_pair->off_target_summary ) {
        my $summary = Load($crispr_pair->off_target_summary);
        if ( my $distance = $summary->{distance} ) {
            $distance =~ s/\+//;
            return 1 if $distance >= 105;
        }
    }

    #TODO should we make pair invalid if no off target summary data? sp12 Mon 18 Nov 2013 08:34:03 GMT
    return;
}

=head2 _format_crispr_off_target_summary

Grab the correct crispr off target summary, one that matches with the specified
off target algorithm.

=cut
sub _format_crispr_off_target_summary {
    my ( $crispr, $off_target_algorithm ) = @_;

    for my $summary ( $crispr->off_target_summaries->all ) {
        next unless $summary->algorithm eq $off_target_algorithm;
        my $summary_details = Load($summary->summary);
        return $summary_details;
    }

    return '';
}

=head2 _format_crispr_pair_off_target_summary

Grab the correct crispr off target summary, one that matches with the specified
off target algorithm.

=cut
sub _format_crispr_pair_off_target_summary {
    my ( $crispr_pair ) = @_;

    if ( $crispr_pair->off_target_summary ) {
        my $summary = Load($crispr_pair->off_target_summary);
        if ( exists $summary->{distance} ) {
            return $summary->{distance};
        }
    }

    return '';
}

=head2 _formated_crispr_locus

desc

=cut
sub _formated_crispr_locus {
    my ( $crispr, $default_assembly ) = @_;

    my $locus = $crispr->search_related( 'loci', { assembly_id => $default_assembly } )->first;

    my $locus_string =  $locus->chr->name . ': ' . $locus->chr_start . ' - ' . $locus->chr_end;

    return $locus_string;
}

=head2 _sort_gene_ids

Sort the input from the gene search box into gene id types

=cut
## no critic(BuiltinFunctions::ProhibitComplexMappings)
sub _sort_gene_ids {
    my ( $genes ) = @_;
    my %sorted_genes = (
        gene_ids         => [],
        marker_symbols   => [],
        ensembl_gene_ids => [],
    );

    my @genes = grep { $_ } map{ chomp; $_; } split /\s/, $genes;

    for my $gene ( @genes ) {
        next unless $gene;
        if ( $gene =~ /HGNC:\d+/ || $gene =~ /MGI:\d+/  ) {
            push @{ $sorted_genes{gene_ids} }, $gene;
        }
        elsif ( $gene =~ /ENS(MUS)?G\d+/ ) {
            push @{ $sorted_genes{ensembl_gene_ids} }, $gene;
        }
        else {
            #assume its a marker symbol
            push @{ $sorted_genes{marker_symbols} }, lc($gene);
        }
    }

    return \%sorted_genes;
}
## use critic

=head2 get_design_targets_data

Get all design_targets data to build the summary grid.

=cut
sub get_design_targets_data {
    my $schema = shift;
    my $species = shift;

    my $project = "Core";
    my $sponsor = $schema->retrieve_sponsor({ id => $project });
    my @genes_list_results = $sponsor->projects;

    my @genes_list;
    foreach my $row (@genes_list_results) {
        my $gene = $row->gene_id;
        push(@genes_list, $gene);
    };

    my $genes_list_ref = \@genes_list;


    my @dt_results = $schema->resultset('DesignTarget')->search({
            species_id        => "$species",
            gene_id     => {
                '-in' => $genes_list_ref
            }
    });

    #my $gene_list_rs = $schema->resultset('Project')->search( { sponsor_id => $project } );
    #my @dt_results = $schema->resultset('DesignTarget')->search(
        #{
            #species_id => $species,
            #gene_id => { '-in' => $gene_list_rs->get_column('gene_id')->as_query },
        #}
    #);

    my $design_data = bulk_designs_for_design_targets( $schema, \@dt_results, $species );

    my @report_data;
    for my $dt ( @{ \@dt_results } ) {
        my %data;
        my $crisprs = crisprs_for_design_target( $schema, $dt );

        $data{'design_target'} = $dt;
        $data{'designs'} = $design_data->{ $dt->id };
        $data{'crisprs'} = $crisprs;

        push @report_data, \%data;
    }

    my @dt;
    foreach my $row (@report_data) {
        my $designs = $row->{'designs'};
        my $design_count = scalar @$designs;
        my $crisprs = $row->{'crisprs'};
        my $crisprs_count = scalar @$crisprs;
        push(@dt, {
            id => $row->{'design_target'}->id,
            marker_symbol => $row->{'design_target'}->marker_symbol,
            ensembl_gene_id => $row->{'design_target'}->ensembl_gene_id,
            ensembl_exon_id => $row->{'design_target'}->ensembl_exon_id,
            exon_size => $row->{'design_target'}->exon_size,
            exon_rank => $row->{'design_target'}->exon_rank,
            canonical_transcript => $row->{'design_target'}->canonical_transcript,
            species_id => $row->{'design_target'}->species_id,
            assembly_id => $row->{'design_target'}->assembly_id,
            build_id => $row->{'design_target'}->build_id,
            chr_id => $row->{'design_target'}->chr_id,
            chr_start => $row->{'design_target'}->chr_start,
            chr_end => $row->{'design_target'}->chr_end,
            chr_strand => $row->{'design_target'}->chr_strand,
            automatically_picked => $row->{'design_target'}->automatically_picked,
            comment => $row->{'design_target'}->comment,
            gene_id => $row->{'design_target'}->gene_id,
            design_count => $design_count,
            designs => join( q{, }, @$designs),
            crisprs => $crisprs_count,
        } );
    }

    return @dt;
}

=head2 target_overlaps_exon

Check if target overlaps a exon ( or any two sets of coordiantes overlap )
- First 2 parameters should be the target start and target end
- Next 2 parameters should be the exon start and exon end

Note: this does not check if the chromosome is the same.

=cut
sub target_overlaps_exon {
    my ( $target_start, $target_end, $exon_start, $exon_end ) = @_;

    if (   $target_start < $exon_start
        && $target_end > $exon_end )
    {
        return 1;
    }
    elsif ($target_start >= $exon_start
        && $target_start <= $exon_end )
    {
        return 1;
    }
    elsif ($target_end >= $exon_start
        && $target_end <= $exon_end )
    {
        return 1;
    }

    return;
}

1;
