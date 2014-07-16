package LIMS2::Model::Util::GenomeBrowser;
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
        gibson_designs_for_region
        design_oligos_to_gff
        primers_for_crispr_pair
        crispr_primers_to_gff
        unique_crispr_data
        unique_crispr_data_to_gff
    ) ]
};

use Log::Log4perl qw( :easy );

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
            ],
        }
    );


    return $crisprs_rs;
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
            $crispr_format_hash{'type'} = 'CDS';
            if ($crispr_r->crispr->pam_right) {
                # pam_right was 1
                $crispr_format_hash{'end'} = $crispr_r->chr_end - 2;
            }
            else {
                # pam_right was 0
                $crispr_format_hash{'start'} = $crispr_r->chr_start + 2;
            }
            $crispr_format_hash{'attributes'} =     'ID='
                    . '1_' . $crispr_r->crispr_id . ';'
                    . 'Parent=C_' . $crispr_r->crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->crispr_id . ';'
                    . 'color=#45A825'; # greenish
            my $crispr_child_a_datum = prep_gff_datum( \%crispr_format_hash );
            if ($crispr_r->crispr->pam_right){
                $crispr_format_hash{'end'} = $crispr_r->chr_end;
                $crispr_format_hash{'start'} = $crispr_r->chr_end - 2;
            }
            else {
                $crispr_format_hash{'start'} = $crispr_r->chr_start;
                $crispr_format_hash{'end'} = $crispr_r->chr_start + 2
            }
            $crispr_format_hash{'attributes'} =     'ID='
                    . '2_' . $crispr_r->crispr_id . ';'
                    . 'Parent=C_' . $crispr_r->crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->crispr_id . ';'
                    . 'color=#DDC808'; # yellowish
            my $crispr_child_b_datum = prep_gff_datum( \%crispr_format_hash );

            push @crisprs_gff, $crispr_parent_datum, $crispr_child_a_datum, $crispr_child_b_datum ;
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
                    . $crispr_r->pair_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->pair_id
                );
            my $crispr_pair_parent_datum = prep_gff_datum( \%crispr_format_hash );
            $crispr_format_hash{'type'} = 'CDS';
            $crispr_format_hash{'end'} = $crispr_r->left_crispr_end;
            $crispr_format_hash{'attributes'} =     'ID='
                    . $crispr_r->left_crispr_id . ';'
                    . 'Parent=' . $crispr_r->pair_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->left_crispr_id . ';'
                    . 'color=#AA2424'; # reddish
            my $crispr_left_datum = prep_gff_datum( \%crispr_format_hash );
            $crispr_format_hash{'start'} = $crispr_r->right_crispr_start;
            $crispr_format_hash{'end'} = $crispr_r->right_crispr_end;
            $crispr_format_hash{'attributes'} =     'ID='
                    . $crispr_r->right_crispr_id . ';'
                    . 'Parent=' . $crispr_r->pair_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_r->right_crispr_id . ';'
                    . 'color=#1A8599'; # blueish
#            $crispr_format_hash{'attributes'} = $crispr_r->pair_id;
            my $crispr_right_datum = prep_gff_datum( \%crispr_format_hash );
            push @crisprs_gff, $crispr_pair_parent_datum, $crispr_left_datum, $crispr_right_datum ;
        }


    return \@crisprs_gff;
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
                    . 'color=#45A825'; # greenish
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

    foreach my $tag ( qw/ G P S / ) {
        for my $num ( 1..2 ){
            $primer_groups{$tag . '_' . $num} = {
                $tag . 'F' . $num => $crispr_primers->{ $tag . 'F' . $num},
                $tag . 'R' . $num => $crispr_primers->{ $tag . 'R' . $num},
                # Add the start and end coords
                'chr_start' => $crispr_primers->{ $tag . 'F' . $num}->{'chr_start'},
                'chr_end'   => $crispr_primers->{ $tag . 'R' . $num}->{'chr_end'},
            }
        }
    }
    delete $primer_groups{'S_2'}; # only one set of sequencing primers

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
            $crispr_format_hash{'type'} = 'CDS';
            $crispr_format_hash{'end'} = $pair->{'left_crispr'}->{'chr_end'};
            $crispr_format_hash{'attributes'} =     'ID='
                    . $pair->{'left_crispr'}->{'id'} . ';'
                    . 'Parent=' . $crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $pair->{'left_crispr'}->{'id'} . ';'
                    . 'color=#AA2424'; # reddish
            my $crispr_left_datum = prep_gff_datum( \%crispr_format_hash );
            $crispr_format_hash{'start'} = $pair->{'right_crispr'}->{'chr_start'};
            $crispr_format_hash{'end'} = $pair->{'right_crispr'}->{'chr_end'};
            $crispr_format_hash{'attributes'} =     'ID='
                    . $pair->{'right_crispr'}->{'id'} . ';'
                    . 'Parent=' . $crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $pair->{'right_crispr'}->{'id'} . ';'
                    . 'color=#1A8599'; # blueish
            my $crispr_right_datum = prep_gff_datum( \%crispr_format_hash );
            push @crispr_data_gff, $crispr_pair_parent_datum, $crispr_left_datum, $crispr_right_datum ;

        }
        elsif ($crispr_type eq 'crispr_single') {
            my $crispr = $crispr_data->{$crispr_type}->{$crispr_id}->{'left_crispr'};
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
                    . 'C_' . $crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_id
                );
            my $crispr_parent_datum = prep_gff_datum( \%crispr_format_hash );
            $crispr_format_hash{'type'} = 'CDS';
            $crispr_format_hash{'attributes'} =     'ID='
                    . $crispr_id . ';'
                    . 'Parent=C_' . $crispr_id . ';'
                    . 'Name=' . 'LIMS2' . '-' . $crispr_id . ';'
                    . 'color=#45A825'; # greenish
            my $crispr_child_datum = prep_gff_datum( \%crispr_format_hash );
            push @crispr_data_gff, $crispr_parent_datum, $crispr_child_datum ;
        }
    return \@crispr_data_gff;
}

1;
