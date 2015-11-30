package LIMS2::Model::Util::GenomeBrowser;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::GenomeBrowser::VERSION = '0.354';
}
## use critic

use strict;
use warnings FATAL => 'all';


=head1 NAME

LIMS2::Model::Util::GenomeBrowser

=head1 DESCRIPTION


=cut

use Sub::Exporter -setup => {
    exports => [ qw(
        crisprs_for_region
        crisprs_to_gff
        crispr_pairs_for_region
        crispr_pairs_to_gff
        generic_designs_for_region
        gibson_designs_for_region
        design_oligos_to_gff
        generic_design_oligos_to_gff
        primers_for_crispr_pair
        crispr_primers_to_gff
        unique_crispr_data
        unique_crispr_data_to_gff
        crispr_groups_for_region
        crispr_groups_to_gff
    ) ]
};

use Log::Log4perl qw( :easy );
use Data::Dumper;

=head2 crisprs_for_region

Find crisprs for a specific chromosome region. The search is not design
related. The method accepts species, chromosome id, start and end coordinates.

This method is used by the browser REST api to server data for the genome browser.

dp10
=cut

sub crisprs_for_region {
    my $schema = shift;
    my $params = shift;

    # Chromosome number is looked up in the chromosomes table to get the chromosome_id
    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $crisprs_rs = $schema->resultset('CrisprLocus')->search(
        {
            'assembly_id' => $params->{assembly_id},
            'chr_id'      => $params->{chromosome_id},
            # need all the crisprs starting with values >= start_coord
            # and whose start values are <= end_coord
            'chr_start'   => { -between => [
                $params->{start_coord},
                $params->{end_coord},
                ],
            },
        },
    );

    return $crisprs_rs;
}

=head crispr_pairs_for_region

Returns a resultset containing the paired Crisprs for the region defined by params.

Individual crisprs for a region on a chromosome must be looked up in the CrisprPair table.
This is done by a join pulling back all the pairs in one go.

=cut

sub crispr_pairs_for_region {
    my $schema = shift;
    my $params = shift;


    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $crisprs_rs = $schema->resultset('CrisprBrowserPairs')->search( {},
        {
            bind => [
                $params->{start_coord},
                $params->{end_coord},
                $params->{chromosome_id},
                $params->{assembly_id},
                $params->{assembly_id}, # That is correct, assembly_id is used twice in the query
            ],
        }
    );


    return $crisprs_rs;
}

sub crispr_groups_for_region {
    my $schema = shift;
    my $params = shift;

    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $crisprs_rs = $schema->resultset('CrisprBrowserGroups')->search( {},
        {
            bind => [
                $params->{start_coord},
                $params->{end_coord},
                $params->{chromosome_id},
                $params->{assembly_id},
            ],
        }
    );

    return $crisprs_rs;
}

sub crispr_genotyping_primers_for_region {
    my $schema = shift;
    my $params = shift;

    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $crisprs_rs = $schema->resultset('CrisprBrowserGroups')->search( {},
        {
            bind => [
                $params->{start_coord},
                $params->{end_coord},
                $params->{chromosome_id},
                $params->{assembly_id},
            ],
        }
    );

    return $crisprs_rs;
}



sub genotyping_primers_for_region {
    my $schema = shift;
    my $params = shift;

    $params->{'chromosome_id'} = retrieve_chromosome_id( $schema, $params->{'species'}, $params->{'chromosome_number'} );

    my $genotyping_primer_rs = $schema->resultset('GenotypingPrimer')->search({
            'genotyping_primer_loci.start' => { '>=', $params->{'start_coord'} },
            'genotyping_primer_loci.end' => { '<=', $params->{'end_coord'} },
            'genotyping_primer_loci.chr_id' => $params->{'chromosome_id'},
            'genotyping_primer_loci.assembly_id' => $params->{'assembly_id'},
        },
        {
            'prefetch'   => ['genotyping_primer_loci'],
        },
    );

    my %g_primer_hash;
    # The genotyping primer table has no unique constraint and may have multiple redundant entries
    # So the %g_primer_hash gets rid of the redundancy
    # Old Mouse GF/GR primers have no locus information
    #

    while ( my $g_primer = $genotyping_primer_rs->next ) {
        if ( $g_primer->genotyping_primer_type_id =~ m/G[FR][12]/ ) {
            last if $g_primer->genotyping_primer_loci->count == 0;
            $g_primer_hash{ $g_primer->genotyping_primer_type_id } = {
                'primer_seq' => $g_primer->seq,
                'chr_start' => $g_primer->genotyping_primer_loci->first->chr_start,
                'chr_end' => $g_primer->genotyping_primer_loci->first->chr_end,
                'chr_id' => $g_primer->genotyping_primer_loci->first->chr_id,
                'chr_name' => $g_primer->genotyping_primer_loci->first->chr->name,
                'chr_strand' => $g_primer->genotyping_primer_loci->first->chr_strand,
                'assembly_id' => $g_primer->genotyping_primer_loci->single->assembly_id,
            }
        }
    }

    return \%g_primer_hash;
}

=head crisprs_for_region_as_arrayref

Return and array of hashrefs properly inflated for the browser.
This is suitable for serialisation as JSON.

=cut

sub crisprs_for_region_as_arrayref {
    my $schema = shift;
    my $params = shift;

    my $crisprs_rs = crisprs_for_region( $schema, $params ) ;
    $crisprs_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @crisprs;

    while ( my $hashref = $crisprs_rs->next ) {
        push @crisprs, $hashref;
    }

    return \@crisprs;
}

sub retrieve_chromosome_id {
    my $schema = shift;
    my $species = shift;
    my $chromosome_number = shift;

    my $chr_id = $schema->resultset('Chromosome')->find( {
            'species_id' => $species,
            'name'       => $chromosome_number,
        }
    );
    return $chr_id->id;
}

=head crisprs_to_gff

Return a reference to an array of strings.
The format of each string is standard GFF3 - that is hard tab separated fields.

=cut

sub crisprs_to_gff {
    my $crisprs_rs = shift;
    my $params = shift;

    my @crisprs_gff;

    push @crisprs_gff, "##gff-version 3";
    push @crisprs_gff, '##sequence-region lims2-region '
        . $params->{'start_coord'}
        . ' '
        . $params->{'end_coord'} ;
    push @crisprs_gff, '# Crisprs for region '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chromosome_number'}
        . ':'
        . $params->{'start_coord'}
        . '-'
        . $params->{'end_coord'} ;

        while ( my $crispr_r = $crisprs_rs->next ) {
            my %crispr_format_hash = (
                'seqid' => $params->{'chromosome_number'},
                'source' => 'LIMS2',
                'type' => 'Crispr',
                'start' => $crispr_r->chr_start,
                'end' => $crispr_r->chr_end,
                'score' => '.',
                'strand' => $crispr_r->chr_strand eq '-1' ? '-' : '+' ,
                'phase' => '.',
                'attributes' => 'ID='
                    . 'C_' . $crispr_r->crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->crispr_id . ';'
                    . 'seq=' . $crispr_r->crispr->seq . ';'
                    . 'pam_right=' . ($crispr_r->crispr->pam_right // 'N/A') . ';'
                    . 'wge_ref=' . ($crispr_r->crispr->wge_crispr_id // 'N/A')
                );
            my $crispr_parent_datum = prep_gff_datum( \%crispr_format_hash );
            push @crisprs_gff, $crispr_parent_datum;

            my $crispr_display_info = {
                id => $crispr_r->crispr_id,
                chr_start => $crispr_r->chr_start,
                chr_end => $crispr_r->chr_end,
                pam_right => $crispr_r->crispr->pam_right,
                colour => '#45A825', # greenish
            };
            push @crisprs_gff, _make_crispr_and_pam_cds($crispr_display_info, \%crispr_format_hash, 'C_' . $crispr_r->crispr_id);
        }

    return \@crisprs_gff;
}


=head crispr_pairs_to_gff
Returns an array representing a set of strings ready for
concatenation to produce a GFF3 format file.

=cut

sub crispr_pairs_to_gff {
    my $crisprs_rs = shift;
    my $params = shift;

    my @crisprs_gff;

    push @crisprs_gff, "##gff-version 3";
    push @crisprs_gff, '##sequence-region lims2-region '
        . $params->{'start_coord'}
        . ' '
        . $params->{'end_coord'} ;
    push @crisprs_gff, '# Crispr pairs for region '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chromosome_number'}
        . ':'
        . $params->{'start_coord'}
        . '-'
        . $params->{'end_coord'} ;

        while ( my $crispr_r = $crisprs_rs->next ) {
            my $pair_id = $crispr_r->pair_id;
            my %crispr_format_hash = (
                'seqid' => $params->{'chromosome_number'},
                'source' => 'LIMS2',
                'type' => 'crispr_pair',
                'start' => $crispr_r->left_crispr_start,
                'end' => $crispr_r->right_crispr_end,
                'score' => '.',
                'strand' => '+' ,
#                'strand' => '.',
                'phase' => '.',
                'attributes' => 'ID='
                    . $pair_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $pair_id
                );
            my $crispr_pair_parent_datum = prep_gff_datum( \%crispr_format_hash );
            push @crisprs_gff, $crispr_pair_parent_datum;

            my $crispr_display_info = {
                left => {
                    id    => $crispr_r->left_crispr_id,
                    chr_start => $crispr_r->left_crispr_start,
                    chr_end   => $crispr_r->left_crispr_end,
                    pam_right => $crispr_r->left_crispr_pam_right,
                    colour => crispr_colour('left'),
                },
                right => {
                    id    => $crispr_r->right_crispr_id,
                    chr_start => $crispr_r->right_crispr_start,
                    chr_end   => $crispr_r->right_crispr_end,
                    pam_right => $crispr_r->right_crispr_pam_right,
                    colour => crispr_colour('right'),
                }
            };

            foreach my $side ( qw(left right) ){
                my $crispr = $crispr_display_info->{$side};
                push @crisprs_gff, _make_crispr_and_pam_cds($crispr, \%crispr_format_hash, $pair_id);
            }
        }


    return \@crisprs_gff;
}

=head crispr_groups_to_gff
Returns an array representing a set of strings ready for
concatenation to produce a GFF3 format file.

=cut

sub crispr_groups_to_gff {
    my $crisprs_rs = shift;
    my $params = shift;

    my @crisprs_gff;

    push @crisprs_gff, "##gff-version 3";
    push @crisprs_gff, '##sequence-region lims2-region '
        . $params->{'start_coord'}
        . ' '
        . $params->{'end_coord'} ;
    push @crisprs_gff, '# Crispr groups for region '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chromosome_number'}
        . ':'
        . $params->{'start_coord'}
        . '-'
        . $params->{'end_coord'} ;

        my $crispr_groups_hr = classify_groups( $crisprs_rs );
        my @crispr_group_keys = keys %$crispr_groups_hr;
        foreach  my $crispr_group ( @crispr_group_keys ) {
            my %crispr_format_hash = (
                'seqid' => $params->{'chromosome_number'},
                'source' => 'LIMS2',
                'type' => 'crispr_group',
                'start' => $crispr_groups_hr->{$crispr_group}->[0]->{'chr_start'},
                'end' => $crispr_groups_hr->{$crispr_group}->[-1]->{'chr_end'},
                'score' => '.',
                'strand' => '+' ,
#                'strand' => '.',
                'phase' => '.',
                'attributes' => 'ID='
                    . $crispr_group . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_group
                );
            my $crispr_group_parent_datum = prep_gff_datum( \%crispr_format_hash );
            push @crisprs_gff, $crispr_group_parent_datum;

            foreach my $group_member ( @{$crispr_groups_hr->{$crispr_group}} ) {
                my $crispr = {
                    id => $group_member->{'crispr_id'},
                    chr_start => $group_member->{'chr_start'},
                    chr_end => $group_member->{'chr_end'},
                    pam_right => $group_member->{'pam_right'},
                    colour => '#45A825', # greenish
                };
                push @crisprs_gff, _make_crispr_and_pam_cds($crispr, \%crispr_format_hash, $crispr_group);
            }
        }


    return \@crisprs_gff;
}

sub classify_groups {
    my $rs = shift;

    my $crispr_groups = ();
    while ( my $crispr_g = $rs->next ) {
        push @{$crispr_groups->{$crispr_g->crispr_group_id}}, {
            'crispr_id' => $crispr_g->crispr_id,
            'chr_start' => $crispr_g->chr_start,
            'chr_end' => $crispr_g->chr_end,
            'pam_right' => $crispr_g->pam_right,
        };
    }

    return $crispr_groups
}

=head prep_gff_datum
given: hash ref of key value pairs
returns: ref to array of tab separated values

The gff format requires hard tab separated list of values in specified fields.
=cut

sub prep_gff_datum {
    my $datum_hr = shift;

    my @data;

    push @data, @$datum_hr{qw/
        seqid
        source
        type
        start
        end
        score
        strand
        phase
        attributes
        /};
    my $datum = join "\t", @data;
    return $datum;
}

=head
Similar methods for design retrieval and browsing
=cut

sub gibson_designs_for_region {
    my $schema = shift;
    my $params = shift;


    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $oligo_rs = $schema->resultset('GibsonDesignBrowser')->search( {},
        {
            bind => [
                $params->{start_coord},
                $params->{end_coord},
                $params->{chromosome_id},
                $params->{assembly_id},
            ],
        }
    );


    return $oligo_rs;
}

sub generic_designs_for_region {
    my $schema = shift;
    my $params = shift;


    $params->{chromosome_id} = retrieve_chromosome_id( $schema, $params->{species}, $params->{chromosome_number} );

    my $oligo_rs = $schema->resultset('GenericDesignBrowser')->search( {},
        {
            bind => [
                $params->{start_coord},
                $params->{end_coord},
                $params->{chromosome_id},
                $params->{assembly_id},
            ],
        }
    );


    return $oligo_rs;
}

=head design_oligos_to_gff

Only for Gibson designs

=cut
sub design_oligos_to_gff {
    my $oligo_rs = shift;
    my $params = shift;

    my @oligo_gff;

    push @oligo_gff, "##gff-version 3";
    push @oligo_gff, '##sequence-region lims2-region '
        . $params->{'start_coord'}
        . ' '
        . $params->{'end_coord'} ;
    push @oligo_gff, '# Gibson designs for region '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chromosome_number'}
        . ':'
        . $params->{'start_coord'}
        . '-'
        . $params->{'end_coord'} ;

        my $gibson_designs; # collects the primers and coordinates for each design. It is a hashref of arrayrefs.
        $gibson_designs = parse_gibson_designs( $oligo_rs );
        my $design_meta_data;
        $design_meta_data = generate_design_meta_data ( $gibson_designs );
        # The gff parent is generated from the meta data for the design
        # must do this for each design (as there may be several)
        foreach my $design_data ( keys %$design_meta_data ) {
            my %oligo_format_hash = (
                'seqid' => $params->{'chromosome_number'},
                'source' => 'LIMS2',
                'type' =>  $design_meta_data->{$design_data}->{'design_type'},
                'start' => $design_meta_data->{$design_data}->{'design_start'},
                'end' => $design_meta_data->{$design_data}->{'design_end'},
                'score' => '.',
                'strand' => ( $design_meta_data->{$design_data}->{'strand'} eq '-1' ) ? '-' : '+',
                'phase' => '.',
                'attributes' => 'ID='
                    . 'D_' . $design_data . ';'
                    . 'Name=' . 'D_' . $design_data
                );
            my $oligo_parent_datum = prep_gff_datum( \%oligo_format_hash );
            push @oligo_gff, $oligo_parent_datum;

            # process the components of the design
            $oligo_format_hash{'type'} = 'CDS';
            foreach my $oligo ( keys %{$gibson_designs->{$design_data}} ) {
                $oligo_format_hash{'start'} = $gibson_designs->{$design_data}->{$oligo}->{'chr_start'};
                $oligo_format_hash{'end'}   = $gibson_designs->{$design_data}->{$oligo}->{'chr_end'};
                $oligo_format_hash{'strand'} = ( $gibson_designs->{$design_data}->{$oligo}->{'chr_strand'} eq '-1' ) ? '-' : '+';
                $oligo_format_hash{'attributes'} =     'ID='
                    . $oligo . ';'
                    . 'Parent=D_' . $design_data . ';'
                    . 'Name=' . $oligo . ';'
                    . 'color=' . $gibson_designs->{$design_data}->{$oligo}->{'colour'};
                my $oligo_child_datum = prep_gff_datum( \%oligo_format_hash );
                push @oligo_gff, $oligo_child_datum ;
            }
        }

    return \@oligo_gff;
}

sub generic_design_oligos_to_gff {
    my $oligo_rs = shift;
    my $params = shift;

    my @oligo_gff;

    push @oligo_gff, "##gff-version 3";
    push @oligo_gff, '##sequence-region lims2-region '
        . $params->{'start_coord'}
        . ' '
        . $params->{'end_coord'} ;
    push @oligo_gff, '# Generic designs for region '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chromosome_number'}
        . ':'
        . $params->{'start_coord'}
        . '-'
        . $params->{'end_coord'} ;

        my $generic_designs; # collects the primers and coordinates for each design. It is a hashref of arrayrefs.
        $generic_designs = parse_generic_designs( $oligo_rs );
        my $design_meta_data;
        $design_meta_data = generate_generic_design_meta_data ( $generic_designs );
        # The gff parent is generated from the meta data for the design
        # must do this for each design (as there may be several)
        foreach my $design_data ( keys %$design_meta_data ) {
            my %oligo_format_hash = (
                'seqid' => $params->{'chromosome_number'},
                'source' => 'LIMS2',
                'type' =>  $design_meta_data->{$design_data}->{'design_type'},
                'start' => $design_meta_data->{$design_data}->{'design_start'},
                'end' => $design_meta_data->{$design_data}->{'design_end'},
                'score' => '.',
                'strand' => ( $design_meta_data->{$design_data}->{'strand'} eq '-1' ) ? '-' : '+',
                'phase' => '.',
                'attributes' => 'ID='
                    . 'D_' . $design_data . ';'
                    . 'Name=' . 'D_' . $design_data
                );
            my $oligo_parent_datum = prep_gff_datum( \%oligo_format_hash );
            push @oligo_gff, $oligo_parent_datum;

            # process the components of the design
            $oligo_format_hash{'type'} = 'CDS';
            foreach my $oligo ( keys %{$generic_designs->{$design_data}} ) {
                $oligo_format_hash{'start'} = $generic_designs->{$design_data}->{$oligo}->{'chr_start'};
                $oligo_format_hash{'end'}   = $generic_designs->{$design_data}->{$oligo}->{'chr_end'};
                $oligo_format_hash{'strand'} = ( $generic_designs->{$design_data}->{$oligo}->{'chr_strand'} eq '-1' ) ? '-' : '+';
                $oligo_format_hash{'attributes'} =     'ID='
                    . $oligo . ';'
                    . 'Parent=D_' . $design_data . ';'
                    . 'Name=' . $oligo . ';'
                    . 'color=' . $generic_designs->{$design_data}->{$oligo}->{'colour'};
                my $oligo_child_datum = prep_gff_datum( \%oligo_format_hash );
                push @oligo_gff, $oligo_child_datum ;
            }
        }

    return \@oligo_gff;
}


=head parse_gibson_designs
Given and GibsonDesignBrowser Resultset.
Returns hashref of hashrefs keyd on design_id
=cut

sub parse_gibson_designs {
    my $gibson_rs = shift;

    my %design_structure;

    # Note that the result set is ordered first by design_id and then by chr_start
    # so we can rely on all the data for one design to be grouped together
    # and within the group for the oligos to be properly ordered,
    # whether they are on the Watson or Crick strands.

    # When the gff format is generated, 3s, 5s, and Es will be coloured in pairs
    # 5F with 5R, EF with ER, 3F with 3R

    while ( my $gibson = $gibson_rs->next ) {
        $design_structure{ $gibson->design_id } ->
            {$gibson->oligo_type_id} = {
                'design_oligo_id' => $gibson->oligo_id,
                'chr_start' => $gibson->chr_start,
                'chr_end' => $gibson->chr_end,
                'chr_strand' => $gibson->chr_strand,
                'colour'     => gibson_colour( $gibson->oligo_type_id ),
                'design_type' => $gibson->design_type_id,
            };
    }

    return \%design_structure;
}

sub parse_generic_designs {
    my $generic_designs_rs = shift;

    my %design_structure;

    # Note that the result set is ordered first by design_id and then by chr_start
    # so we can rely on all the data for one design to be grouped together
    # and within the group for the oligos to be properly ordered,
    # whether they are on the Watson or Crick strands.

    # When the gff format is generated, 3s, 5s, and Es will be coloured in pairs
    # e.g., 5F with 5R, EF with ER, 3F with 3R

    while ( my $generic_design = $generic_designs_rs->next ) {
        $design_structure{ $generic_design->design_id } ->
            {$generic_design->oligo_type_id} = {
                'design_oligo_id' => $generic_design->oligo_id,
                'chr_start' => $generic_design->chr_start,
                'chr_end' => $generic_design->chr_end,
                'chr_strand' => $generic_design->chr_strand,
                'colour'     => generic_colour( $generic_design->oligo_type_id ),
                'design_type' => $generic_design->design_type_id,
            };
    }

    return \%design_structure;
}

=head generate_design_meta_data
Given a design_structure hashref provided by the parse_gibson_design method
Returns a design_meta_data hashref containing the start and end coordinates for the entire design

=cut

sub generate_design_meta_data {
    my $gibson_designs = shift;

    my %design_meta_data;
    my @design_keys;

    @design_keys = sort keys %$gibson_designs;

    foreach my $design_key ( @design_keys ) {
        if ( $gibson_designs->{$design_key}->{'3F'}->{'chr_strand'} == 1 ) {
            # calculate length of design on the plus strand
            $design_meta_data{ $design_key } = {
                'design_start' => $gibson_designs->{$design_key}->{'5F'}->{'chr_start'},
                'design_end'   => $gibson_designs->{$design_key}->{'3R'}->{'chr_end'},
                'strand'       => $gibson_designs->{$design_key}->{'5F'}->{'chr_strand'},
                'design_type'  => $gibson_designs->{$design_key}->{'5F'}->{'design_type'},
            };

        }
        else {
            # calculate length of design on the minus strand
            $design_meta_data{ $design_key } = {
                'design_start' => $gibson_designs->{$design_key}->{'3R'}->{'chr_start'},
                'design_end'   => $gibson_designs->{$design_key}->{'5F'}->{'chr_end'},
                'strand'       => $gibson_designs->{$design_key}->{'3R'}->{'chr_strand'},
                'design_type'  => $gibson_designs->{$design_key}->{'5F'}->{'design_type'},
            };
        }
    }

    return \%design_meta_data;
}


=head generate_generic_design_meta_data
This method goes through each design in $generic_designs hashref and fills in $design_meta_data hashref.

$design_meta_data contains information on the start and end coordinates of each design, strand and design_id

=cut
sub generate_generic_design_meta_data {
    my $generic_designs = shift;

    my %design_meta_data;
    my @design_keys;

    @design_keys = sort keys %$generic_designs;

    foreach my $design_key ( @design_keys ) {
        my @oligo_keys = keys %{$generic_designs->{$design_key}};
        my $arbitrary_oligo = $oligo_keys[0];
        # Find the lowest and highest co-ordinates in DNA space
        my $lowest = $generic_designs->{$design_key}->{$arbitrary_oligo}->{'chr_start'};
        my $highest = $generic_designs->{$design_key}->{$arbitrary_oligo}->{'chr_end'};
        while ( my ($primer, $vals) = each %{$generic_designs->{$design_key}} ) {
            $lowest = $vals->{'chr_start'} if $lowest > $vals->{'chr_start'};
            $highest = $vals->{'chr_end'} if $highest < $vals->{'chr_end'};
        }

        $design_meta_data{ $design_key } = {
            'design_start' => $lowest,
            'design_end'   => $highest,
            'strand'       => $generic_designs->{$design_key}->{$arbitrary_oligo}->{'chr_strand'},
            'design_type'  => $generic_designs->{$design_key}->{$arbitrary_oligo}->{'design_type'},
        };

    }

    return \%design_meta_data;
}

sub gibson_colour {
    my $oligo_type_id = shift;

    my %colours = (
        '5F' => '#68D310',
        '5R' => '#68D310',
        'EF' => '#589BDD',
        'ER' => '#589BDD',
        '3F' => '#BF249B',
        '3R' => '#BF249B',
    );
    return $colours{ $oligo_type_id };
}

sub generic_colour {
    my $oligo_type_id = shift;
    # TODO: Why not get this from the database?
    #
    my %colours = (
        '5F' => '#68D310',
        '5R' => '#68D310',
        'EF' => '#589BDD',
        'ER' => '#589BDD',
        '3F' => '#BF249B',
        '3R' => '#BF249B',
        'D3' => '#68D310',
        'D5' => '#68D310',
        'G3' => '#589BDD',
        'G5' => '#589BDD',
        'U3' => '#BF249B',
        'U5' => '#BF249B',
        'N' => '#18D6CD',
    );
    return $colours{ $oligo_type_id };
}

sub crispr_colour {
    my $type = shift;

    my %colours = (
        single => '#45A825', # green
        left   => '#45A825', # green
        right  => '#52CCCC', # bright blue
        pam    => '#1A8599', # blue
        primer => '#45A825', # green
    );
=head
    my %colours = (
        single => '#45A825', # greenish
        left   => '#AA2424', # reddish
        right  => '#1A8599', # blueish
        pam    => '#DDC808', # yellowish
        primer => '#45A825', # greenish
    );
=cut
    return $colours{ $type };
}

# Methods for crispr primer generation and formatting to gff

sub primers_for_crispr_pair{
    my $schema = shift;
    my $params = shift;

    use LIMS2::Model::Util::OligoSelection qw/ retrieve_crispr_primers/;
    my $crispr_primers = LIMS2::Model::Util::OligoSelection::retrieve_crispr_primers($schema, $params  ) ;

    return $crispr_primers;
}

sub crispr_primers_to_gff {
    my $crispr_primers = shift;
    my $params = shift;

    my @crispr_primers_gff;
    if ( scalar keys %$crispr_primers == 0 ) {
        push @crispr_primers_gff, "##gff-version 3";
        push @crispr_primers_gff, '##sequence-region lims2-region '
            . $params->{'start'}
            . ' '
            . $params->{'end'};
        return \@crispr_primers_gff;
    }


    my @type_keys = keys %$crispr_primers;
    my $crispr_type = shift @type_keys;
    my ($crispr_id) = keys %{$crispr_primers->{$crispr_type}};

    push @crispr_primers_gff, "##gff-version 3";
    push @crispr_primers_gff, '##sequence-region lims2-region '
        . $params->{'start'}
        . ' '
        . $params->{'end'};
    push @crispr_primers_gff, '# Crispr primers for '
        . $crispr_type . ':' . $crispr_id . ' '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chr'}
        . ':'
        . $params->{'start'}
        . '-'
        . $params->{'end'} ;

        # Crispr primers are pairs consisting of 2 chars and a digit. These will form the object to be rendered.
        # However, there is no LIMS2 identifier for a primer pair combination - so we invent one here.
        # Each (GF1,GR1) is a pair, so is (GF2,GR2), (SF1,SR1), (SF2,SR2) etc.
        # So, the hash needs splitting into sub-hashes, grouped by 1st character of label, then by last character of label.
        # The middle character gives the orientation.
        #
        my $primer_groups = group_primers_by_pair( $crispr_primers->{$crispr_type}->{$crispr_id} );

        while ( my ($primer_group, $val) = each %$primer_groups ) {
            next if ! $primer_groups->{$primer_group}->{'chr_start'};
            my $g_start = $primer_groups->{$primer_group}->{'chr_start'};
            my $g_end = $primer_groups->{$primer_group}->{'chr_end'};
            my %primer_format_hash = (
                'seqid' => $params->{'chr'},
                'source' => 'LIMS2',
                'type' => 'CrisprPrimer',
                'start' => ($g_start < $g_end ? $g_start : $g_end),
                'end' => ($g_end > $g_start ? $g_end : $g_start),
                'score' => '.',
                'strand' => ($g_start < $g_end ? '+' : '-') ,
                'phase' => '.',
                'attributes' => 'ID='
                    . $primer_group . ';'
                    . 'Name=' . 'LIMS2' . '-' . $primer_group
                );
            my $primer_parent_datum = prep_gff_datum( \%primer_format_hash );
            my @primer_child_data;
            $primer_format_hash{'type'} = 'CDS';
            foreach my $primer_key ( grep { $_ !~ /chr_/ } keys %$val ) {
                my $start = $val->{$primer_key}->{'chr_start'};
                my $end = $val->{$primer_key}->{'chr_end'};
                $primer_format_hash{'start'} = $start < $end ? $start : $end;
                $primer_format_hash{'end'} = $end > $start ? $end : $start;
                $primer_format_hash{'strand'} = ( $val->{$primer_key}->{'chr_strand'} eq '-1' ) ? '-' : '+';
                $primer_format_hash{'attributes'} =     'ID='
                    . $primer_key . ';'
                    . 'Parent=' . $primer_group . ';'
                    . 'Name=' . 'LIMS2' . '-' . $primer_key . ';'
                    . 'color=' . crispr_colour('primer');
                 my $primer_child_datum = prep_gff_datum( \%primer_format_hash );
                 push @primer_child_data, $primer_child_datum;
            }
            push @crispr_primers_gff, $primer_parent_datum, @primer_child_data ;
        }

    return \@crispr_primers_gff;
}

sub group_primers_by_pair {
    my $crispr_primers = shift;

    my %primer_groups;

    foreach my $tag ( qw/ G P S D/ ) {
        for my $num ( 1..2 ){

            my $forward = $tag . 'F' . $num;
            my $reverse = $tag . 'R' . $num;
            next unless ($crispr_primers->{$forward} and $crispr_primers->{$reverse});

            $primer_groups{$tag . '_' . $num} = {
                $forward => $crispr_primers->{ $forward },
                $reverse => $crispr_primers->{ $reverse },
                # Add the start and end coords
                'chr_start' => $crispr_primers->{ $forward }->{'chr_start'},
                'chr_end'   => $crispr_primers->{ $reverse }->{'chr_end'},
            }
        }
    }

    # special case for crispr group primer ER1 which pairs with DF1
    # (DR1 also pairs with DF1 but this is handled in loop above)
    if($crispr_primers->{'DF1'} and $crispr_primers->{'ER1'}){
        $primer_groups{'DE_1'} = {
            'DF1' => $crispr_primers->{'DF1'},
            'ER1' => $crispr_primers->{'ER1'},
            'chr_start' => $crispr_primers->{'DF1'}->{'chr_start'},
            'chr_end'   => $crispr_primers->{'ER1'}->{'chr_end'},
        }
    }

    return \%primer_groups;
}

=head unique_crispr_data

=cut

sub unique_crispr_data  {
    my $schema = shift;
    my $params = shift;

    use LIMS2::Model::Util::OligoSelection qw/ retrieve_crispr_data_for_id/;
    my $crispr_primers = LIMS2::Model::Util::OligoSelection::retrieve_crispr_data_for_id($schema, $params  ) ;

    return $crispr_primers;
}

sub unique_crispr_data_to_gff {
    my $crispr_data = shift;
    my $params = shift;

    my @crispr_data_gff;

    push @crispr_data_gff, "##gff-version 3";
    push @crispr_data_gff, '##sequence-region lims2-region '
        . $params->{'start'}
        . ' '
        . $params->{'end'};
    my @type_keys = keys %$crispr_data;
    my $crispr_type = shift @type_keys;
    my ($crispr_id) = keys %{$crispr_data->{$crispr_type}};
    push @crispr_data_gff, '# Unique Crispr data for '
        . $crispr_type . ':' . $crispr_id . ' '
        . $params->{'species'}
        . '('
        . $params->{'assembly_id'}
        . ') '
        . $params->{'chr'}
        . ':'
        . $params->{'start'}
        . '-'
        . $params->{'end'} ;

        # Use this array to store a single crispr
        # or list of crisprs from crispr group
        my @single_crisprs;

        if ( $crispr_type eq 'crispr_pair') {
            my $pair = $crispr_data->{$crispr_type}->{$crispr_id};
            my %crispr_format_hash = (
                'seqid' => $params->{'chr'},
                'source' => 'LIMS2',
                'type' => 'crispr_pair',
                'start' => $pair->{'left_crispr'}->{'chr_start'},
                'end' => $pair->{'right_crispr'}->{'chr_end'},
                'score' => '.',
                'strand' => '+' ,
#                'strand' => '.',
                'phase' => '.',
                'attributes' => 'ID='
                    . $crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_id
                );
            my $crispr_pair_parent_datum = prep_gff_datum( \%crispr_format_hash );
            push @crispr_data_gff, $crispr_pair_parent_datum;

            my $crispr_display_info = {
                left => $pair->{left_crispr},
                right => $pair->{right_crispr},
            };
            $crispr_display_info->{left}->{colour} = crispr_colour('left');
            $crispr_display_info->{right}->{colour} = crispr_colour('right');

            foreach my $side ( qw(left right) ){
                my $crispr = $crispr_display_info->{$side};
                push @crispr_data_gff, _make_crispr_and_pam_cds($crispr, \%crispr_format_hash, $crispr_id);
            }

        }
        elsif ($crispr_type eq 'crispr_single') {
            push @single_crisprs, $crispr_data->{$crispr_type}->{$crispr_id}->{'left_crispr'};
        }
        elsif ($crispr_type eq 'crispr_group'){
            @single_crisprs = @{ $crispr_data->{$crispr_type}->{$crispr_id} || [] };
        }

        # Now generate the single crispr GFF for single or group
        foreach my $crispr (@single_crisprs){
            my $this_crispr_id = $crispr->{'id'};
            my %crispr_format_hash = (
                'seqid' => $params->{'chr'},
                'source' => 'LIMS2',
                'type' => 'Crispr',
                'start' => $crispr->{'chr_start'},
                'end' => $crispr->{'chr_end'},
                'score' => '.',
                'strand' => '+' ,
                'phase' => '.',
                'attributes' => 'ID='
                    . 'C_' . $this_crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $this_crispr_id
                );
            my $crispr_parent_datum = prep_gff_datum( \%crispr_format_hash );
            push @crispr_data_gff, $crispr_parent_datum;

            $crispr->{colour} = crispr_colour('single');
            push @crispr_data_gff, _make_crispr_and_pam_cds($crispr, \%crispr_format_hash, 'C_'.$this_crispr_id);
        }

    return \@crispr_data_gff;
}

sub _make_crispr_and_pam_cds{
    my ($crispr_display_info, $crispr_format_hash, $parent_id) = @_;

    # crispr display info must contain keys:
    # id, chr_start, chr_end, pam_right, colour

    my $crispr = $crispr_display_info;
    if(defined $crispr->{pam_right}){
        my ($pam_start, $pam_end);
        if($crispr->{pam_right}){
            $crispr_format_hash->{'start'} = $crispr->{chr_start};
            $crispr_format_hash->{'end'} = $crispr->{chr_end} - 2;
            $pam_start =  $crispr->{chr_end} - 2;
            $pam_end = $crispr->{chr_end};
        }
        else{
            $crispr_format_hash->{'start'} = $crispr->{chr_start} + 2;
            $crispr_format_hash->{'end'} = $crispr->{chr_end};
            $pam_start = $crispr->{chr_start};
            $pam_end = $crispr->{chr_start} + 2;
        }

        # This is the crispr without PAM
        $crispr_format_hash->{'type'} = 'CDS';
        $crispr_format_hash->{'attributes'} =     'ID='
            . 'Crispr_' . $crispr->{id} . ';'
            . 'Parent=' . $parent_id . ';'
            . 'Name=LIMS2-' . $crispr->{id} . ';'
            . 'color=' .$crispr->{colour};
        my $crispr_datum = prep_gff_datum( $crispr_format_hash );

        # This is the PAM
        $crispr_format_hash->{start} = $pam_start;
        $crispr_format_hash->{end} = $pam_end;
        $crispr_format_hash->{'attributes'} = 'ID='
                . 'PAM_' . $crispr->{id} . ';'
                . 'Parent=' . $parent_id . ';'
                . 'Name=LIMS2-' . $crispr->{id} . ';'
                . 'color=' . crispr_colour('pam');
        my $pam_child_datum = prep_gff_datum( $crispr_format_hash );

        return ($crispr_datum, $pam_child_datum);
    }
    else{
        # We don't have pam right flag so just make the crispr cds
        $crispr_format_hash->{start} = $crispr->{chr_start};
        $crispr_format_hash->{end} = $crispr->{chr_end};
        $crispr_format_hash->{'type'} = 'CDS';
        $crispr_format_hash->{'attributes'} =     'ID='
            . $crispr->{id} . ';'
            . 'Parent=' . $parent_id . ';'
            . 'Name=' . $crispr->{id} . ';'
            . 'color=' .$crispr->{colour};
        my $crispr_datum = prep_gff_datum( $crispr_format_hash );
        return $crispr_datum;
    }

    return;
}
1;
