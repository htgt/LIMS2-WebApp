package LIMS2::Model::Util::DesignTargets;
use strict;
use warnings FATAL => 'all';

=head1 NAME

LIMS2::Model::Util::DesignTargets

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw( designs_matching_design_target_via_exon_name
                     designs_matching_design_target_via_coordinates
                     find_design_targets
                     design_target_report_for_genes
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

Bulk lookup to speed things up, must specify species_id

=cut
sub bulk_designs_for_design_targets {
    my ( $schema, $design_targets, $species_id ) = @_;

    my @gene_designs = $schema->resultset('GeneDesign')->search(
        {
            gene_id => { 'IN' => [ map{ $_->gene_id } @{ $design_targets } ] },
            'design.species_id' => $species_id,
        },
        {
            join     => 'design',
            prefetch => 'design'
        },
    );

    my %data;
    for my $dt ( @{ $design_targets } ) {
        my @matching_designs;
        my @dt_designs = map{ $_->design } grep{ $_->gene_id eq $dt->gene_id } @gene_designs;
        for my $design ( @dt_designs ) {
            my $di = LIMS2::Model::Util::DesignInfo->new( design => $design );
            if ( $dt->chr_start > $di->target_region_start
                && $dt->chr_end < $di->target_region_end
            ) {
                push @matching_designs, $design;
            }
        }
        $data{ $dt->id } = \@matching_designs;
    }

    return \%data;
}

=head2 crisprs_for_design_target

Find crisprs that correspond to given design target

=cut
sub crisprs_for_design_target {
    my ( $schema, $design_target ) = @_;

    my @crisprs = $schema->resultset('Crispr')->search(
        {
            'loci.assembly_id' => $design_target->assembly_id,
            'loci.chr_id'      => $design_target->chr_id,
            'loci.chr_start'   => { '>' => $design_target->chr_start },
            'loci.chr_end'     => { '<' => $design_target->chr_end },
        },
        {
            join     => 'loci',
            prefetch => 'off_target_summaries',
        }
    );

    return \@crisprs;
}

=head2 find_design_targets

Given a list of gene identifiers find any design targets

=cut
sub find_design_targets {
    my ( $schema, $genes, $species_id ) = @_;

    my @design_targets = $schema->resultset('DesignTarget')->search(
        {
            gene_id    => { 'IN' => $genes  },
            species_id => $species_id,
        },
        {
            order_by => 'gene_id'
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
    my ( $schema, $genes, $species_id  ) = @_;

    my $design_targets = find_design_targets( $schema, $genes, $species_id );
    my $design_data = bulk_designs_for_design_targets( $schema, $design_targets, $species_id );

    my @report_data;
    for my $dt ( @{ $design_targets } ) {
        my %data;
        my $crisprs = crisprs_for_design_target( $schema, $dt );

        $data{'design_target'} = $dt;
        $data{'designs'} = $design_data->{ $dt->id };
        $data{'crisprs'} = $crisprs;

        push @report_data, \%data;
    }

    return _format_report_data( \@report_data );
}

=head2 _rank_crisprs

sort crisprs by off target hits, ranking is weighted my importance of hit type:
exon > intron > intergenic

=cut
sub _rank_crisprs {
    my ( $crispr, $rank_algorithm ) = @_;

    my $off_target_summary = first{ $_->algorithm eq $rank_algorithm } $crispr->off_target_summaries->all;
    return 1000 unless $off_target_summary;
    my $summary = Load($off_target_summary->summary);

    return ($summary->{Exons} * 100) + ($summary->{Introns} * 10) + $summary->{Intergenic};
}

=head2 _format_report_data

Manipulate data into format we can easily display in a spreadsheet

=cut
sub _format_report_data {
    my ( $data ) = @_;
    my @report_rows;
    my %report_data;

    for my $datum ( @{ $data } ) {
        my $dt = $datum->{'design_target'};
        my %design_target_data = (
          design_target_id => $dt->id,
          marker_symbol    => $dt->marker_symbol,
          gene_id          => $dt->gene_id,
          ensembl_exon_id  => $dt->ensembl_exon_id,
          exon_size        => $dt->exon_size,
          exon_rank        => $dt->exon_rank,
        );

        my $crispr_data = _format_crispr_data( $datum->{crisprs}, 'strict', 5 );
        my $design_data = _format_design_data( $datum->{designs} );

        $design_target_data{crispr_num} = scalar( @{ $crispr_data } );
        $design_target_data{design_num} = scalar( @{ $design_data } );

        if ( @{ $design_data } ) {
            for my $design ( @{ $design_data } ) {
                if ( @{ $crispr_data } ) {
                    for my $crispr ( @{ $crispr_data } ) {
                        push @report_rows, {
                            %design_target_data, %{ $design }, %{ $crispr }
                        }
                    }
                }
                else {
                    push @report_rows, {
                        %design_target_data, %{ $design }
                    }
                }
            }
        }
        else {
            if ( @{ $crispr_data } ) {
                for my $crispr ( @{ $crispr_data } ) {
                    push @report_rows, {
                        %design_target_data, %{ $crispr }
                    }
                }
            }
            else {
                push @report_rows, {
                    %design_target_data
                }
            }
        }
    }


    $report_data{rows} = \@report_rows;
    return \%report_data;
}

=head2 _format_crispr_data

Format the crispr data, add information about crisprs presense on Crispr plates.

=cut
sub _format_crispr_data {
    my ( $crisprs, $rank_algorithm, $num_crisprs ) = @_;
    my @crispr_data;
    $rank_algorithm ||= 'strict';
    $num_crisprs ||= 5;

    # rank crisprs if we have more than the maximum amount we want to show
    my @ranked_crisprs;
    if ( scalar( @{ $crisprs } ) > $num_crisprs ) {
        @ranked_crisprs
        = sort { _rank_crisprs( $a, $rank_algorithm ) <=> _rank_crisprs( $b, $rank_algorithm ) } @{$crisprs};
    }
    else {
        @ranked_crisprs = @{ $crisprs };
    }

    my $crispr_count = 0;
    for my $c ( @ranked_crisprs ) {
        my %data = ( crispr_id => $c->id );
        for my $summary ( $c->off_target_summaries->all ) {
            my $valid = $summary->outlier ? 'no' : 'yes';
            push @{ $data{outlier} }, $summary->algorithm . ': ' . $valid;
            push @{ $data{summary} }, $summary->algorithm . ': ' . $summary->summary;
        }
        last if $crispr_count++ >= $num_crisprs;

        my @process_crisprs = $c->process_crisprs->all;
        unless ( @process_crisprs ) {
            push @crispr_data, \%data;
            next;
        }

        my @crispr_well_data;
        for my $crispr_process ( @process_crisprs ) {
            my $process_output_well = $crispr_process->process->process_output_wells->first;
            next unless $process_output_well;
            my $crispr_well = $process_output_well->well;
            push @crispr_well_data, "$crispr_well";
        }
        $data{crispr_wells} = join( ',', @crispr_well_data );
        push @crispr_data, \%data;
    }

    return \@crispr_data;
}

=head2 _format_design_data

Format design data to show in reports.

=cut
sub _format_design_data {
    my ( $designs ) = @_;
    my @design_data;

    for my $design ( @{ $designs } ) {
        push @design_data, {
            design_id => $design->id,
            design_type => $design->design_type_id,
        }
    }

    return \@design_data;
}

1;
