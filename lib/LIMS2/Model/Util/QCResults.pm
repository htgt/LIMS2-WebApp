package LIMS2::Model::Util::QCResults;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw(
        retrieve_qc_run_results
        retrieve_qc_run_summary_results
        retrieve_qc_run_seq_well_results
        retrieve_qc_alignment_results
        retrieve_qc_seq_read_sequences
        retrieve_qc_eng_seq_sequence
    ) ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use Bio::SeqIO;
use List::Util qw(sum);
use LIMS2::Exception;
use LIMS2::Model::Util::WellName qw ( to384 );
use HTGT::QC::Config;
use HTGT::QC::Util::Alignment qw( alignment_match );
use HTGT::QC::Util::CigarParser;

sub retrieve_qc_run_results {
    my ( $qc_run ) = @_;

    unless( $qc_run ) {
        die; #TODO throw better error
    }

    my $vector_stage        = _get_vector_stage( $qc_run );
    my $expected_design_loc = _design_loc_for_qc_template_plate( $qc_run );
    my $read_length_for     = _read_lengths_for_seq_reads( $qc_run, $vector_stage );

    my @qc_test_results = $qc_run->qc_test_results(
        {}, { prefetch => [ 'qc_eng_seq', 'qc_run_seq_well' ] });

    my @results = map{ _parse_qc_test_result( $_, $read_length_for, $expected_design_loc ) } @qc_test_results;

    # Merge in the number of primer reads (this has to be done in a
    # separate loop to catch wells with primer reads but no test results)

    return _merge_number_primer_reads( \@results, $read_length_for );
}

sub retrieve_qc_run_summary_results {
    my ( $qc_run ) = @_;

    my $results = retrieve_qc_run_results( $qc_run );

    my $template_well_rs = $qc_run->qc_template->qc_template_wells;

    my @summary;
    my %seen_design;

    while ( my $template_well = $template_well_rs->next ) {
        next unless $template_well->design_id
            and not $seen_design{ $template_well->design_id }++;

        my %s = (
            design_id => $template_well->design_id,
        );

        my @results = reverse sort {
            ( $a->{pass} || 0 ) <=> ( $b->{pass} || 0 )
                || ( $a->{num_valid_primers} || 0 ) <=> ( $b->{num_valid_primers} || 0 )
                    || ( $a->{valid_primers_score} || 0 ) <=> ( $b->{valid_primers_score} || 0 )
                        || ( $a->{score} || 0 ) <=> ( $b->{score} || 0 )
                            || ( $a->{num_reads} || 0 ) <=> ( $b->{num_reads} || 0 )
                        }
            grep { $_->{design_id} and $_->{design_id} == $template_well->design_id }
                @{ $results };

        if ( my $best = shift @results ) {
            $s{plate_name}    = $best->{plate_name};
            $s{well_name}     = uc $best->{well_name};
            $s{well_name_384} = uc $best->{well_name_384};
            $s{valid_primers} = join( q{,}, @{ $best->{valid_primers} } );
            $s{pass}          = $best->{pass};
        }
        push @summary, \%s;
    }

    return \@summary;
}

sub retrieve_qc_run_seq_well_results {
    my $seq_well = shift;

    my @seq_reads = $seq_well->qc_seq_reads;

    unless ( @seq_reads ) {
        LIMS2::Exception::Validation->throw( 'No sequence reads for qc seq well '
            . $seq_well->plate_name . $seq_well->well_name );
    }

    my @qc_alignments = map { $_->qc_alignments } @seq_reads;

    my @qc_results;
    for my $test_result ( $seq_well->qc_test_results ) {
        my %result;
        $result{design_id} = $test_result->qc_eng_seq->design_id;
        $result{score} = $test_result->score;
        $result{pass} = $test_result->pass;
        $result{qc_test_result_id} = $test_result->id;
        $result{alignments} = [ grep{ $_->qc_eng_seq_id == $test_result->qc_eng_seq->id  } @qc_alignments ];
        push @qc_results, \%result;
    }

    return( \@seq_reads, \@qc_results );
}

sub retrieve_qc_alignment_results {
    my ( $eng_seq_builder, $qc_alignment ) = @_;

    my $qc_eng_seq     = $qc_alignment->qc_eng_seq->as_hash;
    my $eng_seq_method = $qc_eng_seq->{eng_seq_method};
    my $target = $eng_seq_builder->$eng_seq_method( $qc_eng_seq->{eng_seq_params} );
    my $query  = $qc_alignment->qc_seq_read->bio_seq;
    my $cigar  = HTGT::QC::Util::CigarParser->new(strict_mode => 0)->parse_cigar( $qc_alignment->cigar );

    my $match = alignment_match( $query, $target, $cigar, $cigar->{target_start}, $cigar->{target_end} );

    my $target_strand = $qc_alignment->target_strand == 1 ? '+' : '-';

    my $alignment_str = HTGT::QC::Util::Alignment::format_alignment(
        %{$match},
        target_id  => "Target ($target_strand)",
        query_id   => 'Sequence Read',
        line_len   => 72,
        header_len => 12
    );

    return {
         target        => $target->display_id,
         query         => $query->display_id,
         alignment_str => $alignment_str,
         alignment     => $qc_alignment,
    };
}

sub retrieve_qc_seq_read_sequences {
    my ( $seq_well, $format ) = @_;

    my @seq_reads = $seq_well->qc_seq_reads;
    unless ( @seq_reads ) {
        LIMS2::Exception::Validation->throw(
            'No sequence reads for qc seq well ' . $seq_well->plate_name . $seq_well->well_name );
    }

    my $params = _validated_download_seq_params( $format );

    my $filename = 'seq_reads_' . $seq_well->plate_name . $seq_well->well_name . $params->{suffix};

    my $formatted_seq;
    my $seq_io = Bio::SeqIO->new( -fh => IO::String->new( $formatted_seq ), -format => $params->{format} );

    for my $seq_read ( @seq_reads ) {
        $seq_io->write_seq( $seq_read->bio_seq );
    }

    return ( $filename, $formatted_seq );
}

sub retrieve_qc_eng_seq_sequence {
    my ( $eng_seq_builder, $qc_test_result, $format ) = @_;

    my $qc_eng_seq_params = $qc_test_result->qc_eng_seq->as_hash;
    my $eng_seq_method= $qc_eng_seq_params->{eng_seq_method};
    my $qc_eng_seq = $eng_seq_builder->$eng_seq_method( $qc_eng_seq_params->{eng_seq_params} );

    my $params = _validated_download_seq_params( $format );

    my $filename = $qc_eng_seq->display_id . $params->{suffix};

    my $formatted_seq;
    Bio::SeqIO->new(
        -fh => IO::String->new( $formatted_seq ),
        -format => $params->{format}
    )->write_seq( $qc_eng_seq );

    return ( $filename, $formatted_seq );
}

sub _validated_download_seq_params {
    my ( $format ) = @_;

    my %params = (
        format => 'genbank',
    );

    const my %SUFFIX_FOR => ( genbank => '.gbk', fasta => '.fasta' );

    if ( $format ) {
        $format =~ s/^\s+//;
        $format =~ s/\s+$//;
        $format = lc( $format );
        if ( $SUFFIX_FOR{$format} ) {
            $params{format} = $format;
        }
    }

    $params{suffix} = $SUFFIX_FOR{ $params{format} };

    return \%params;
}

sub _read_lengths_for_seq_reads {
    my ( $qc_run, $vector_stage ) = @_;
    my %read_length_for;

    for my $seq_well ( $qc_run->qc_run_seq_wells ) {
        my $plate_name = $seq_well->plate_name;
        my $well_name  = lc($seq_well->well_name);
        for my $seq_read ( $seq_well->qc_seq_reads ) {
            $read_length_for{$plate_name}{$well_name}{$seq_read->primer_name}
                = $seq_read->length;
        }
    }

    %read_length_for = %{ _combine_ABRZ_plates( \%read_length_for ) }
        if $vector_stage eq 'allele';

    return \%read_length_for;
}

sub _design_loc_for_qc_template_plate {
    my ( $qc_run ) = @_;
    my %design_loc_for;
    my @qc_template_wells = $qc_run->qc_template->qc_template_wells(
        {}, { prefetch => [ 'qc_eng_seq' ] }
    );

    for my $well ( map { $_->as_hash } @qc_template_wells ) {
        if ( exists $well->{eng_seq_params}{design_id} ) {
            $design_loc_for{$well->{name}} = $well->{eng_seq_params}{design_id};
        }
    }

    return \%design_loc_for;
}

sub _get_vector_stage{
    my ( $qc_run ) = @_;

    my $profile_name = $qc_run->profile;

    my $profile = HTGT::QC::Config->new->profile( $profile_name );

    return $profile->vector_stage;
}

sub _combine_ABRZ_plates{
    my ( $read_length_for ) = @_;

    my %combined;
    for my $plate_name ( keys %{$read_length_for} ){
        my $plate_name_stem = $plate_name;
        my $plate_type;
        ( $plate_name_stem, $plate_type ) = $plate_name =~ /^(.+)_([ABRZ])_\d$/ if $plate_name =~ /_[ABRZ]_\d$/;
        for my $well_name ( keys %{ $read_length_for->{$plate_name} } ){
            for my $primer ( keys %{ $read_length_for->{$plate_name}{$well_name} } ){
                my $primer_name = $primer;
                $primer_name = $plate_type . '_' . $primer if $plate_type;
                $combined{$plate_name_stem}{$well_name}{$primer_name}
                    = $read_length_for->{$plate_name}{$well_name}{$primer};
            }
        }
    }

    return \%combined;
}

sub _parse_qc_test_result {
    my ( $qc_test_result, $read_length_for, $expected_design_loc ) = @_;

    my $seq_well   = $qc_test_result->qc_run_seq_well;
    my $qc_eng_seq = $qc_test_result->qc_eng_seq;
    my $plate_name = $seq_well->plate_name;
    my $well_name = lc( $seq_well->well_name );
    my %result = (
        plate_name         => $plate_name,
        well_name          => $well_name,
        expected_design_id => $expected_design_loc->{ uc $well_name },
        design_id          => $qc_eng_seq->as_hash->{eng_seq_params}{design_id},
        marker_symbol      => '-',
        pass               => $qc_test_result->pass,
        num_reads          => scalar( keys %{ $read_length_for->{ $plate_name }{ $well_name } } ),
    );

    my $primers = _get_primers_for_seq_well( $seq_well, $read_length_for );

    my @valid_primers = sort { $a cmp $b } grep { $primers->{$_}->{pass} } keys %{ $primers };
    $result{valid_primers}       = \@valid_primers;
    $result{num_valid_primers}   = scalar @valid_primers;
    $result{score}               = sum( 0, map $_->{score}, values %{ $primers } );
    $result{valid_primers_score} = sum( 0, map $primers->{$_}->{score}, @valid_primers );

    while ( my ( $primer_name, $primer ) = each %{ $primers } ) {
        $result{ $primer_name . '_pass' }                = $primer->{pass};
        $result{ $primer_name . '_critical_regions' }    = $primer->{regions};
        $result{ $primer_name . '_target_align_length' } = $primer->{target_align_length};
        $result{ $primer_name . '_score' }               = $primer->{score};
        $result{ $primer_name . '_features' }            = $primer->{features};
        $result{ $primer_name . '_read_length' }         = $primer->{read_length};
    }

    return \%result;
}

sub _get_primers_for_seq_well {
    my ( $seq_well, $read_length_for ) = @_;

    my @qc_seq_reads = $seq_well->qc_seq_reads(
        {},
        { prefetch => [ { qc_alignments => 'qc_alignment_regions' } ] }
    );

    my %primers;
    for my $seq_read ( @qc_seq_reads ) {
        for my $alignment ( $seq_read->qc_alignments ) {
            my $primer_name = $alignment->primer_name;
            $primers{$primer_name}{pass} = $alignment->pass;
            $primers{$primer_name}{score} = $alignment->score;
            $primers{$primer_name}{features} = $alignment->features;
            $primers{$primer_name}{target_align_length}
                = abs( $alignment->target_end - $alignment->target_start );
            $primers{$primer_name}{read_length}
                = $read_length_for->{ $seq_well->plate_name }{ lc( $seq_well->well_name ) }{ $primer_name };

            my @regions;
            for my $region ( $alignment->qc_alignment_regions ) {
                push @regions, $region->name . ': ' . $region->match_count
                    . '/' . $region->length . $region->pass ? 'pass' : 'fail';
            }
            $primers{$primer_name}{regions} = join( q{,}, @regions );
        }
    }

    return \%primers;
}

sub _merge_number_primer_reads {
    my ( $results, $read_length_for ) = @_;
    my @all_results;

    for my $plate_name ( keys %{ $read_length_for } ) {
        for my $well_name ( keys %{ $read_length_for->{ $plate_name } } ) {
            my $num_reads = scalar( keys %{ $read_length_for->{ $plate_name }{ $well_name } } );
            my @these_results
                = grep { $_->{plate_name} eq $plate_name && $_->{well_name} eq $well_name }
                    @{ $results };

            if ( @these_results ) {
                for my $r ( @these_results ) {
                    $r->{num_reads} = $num_reads;
                    $r->{well_name_384} = lc to384( $plate_name, $well_name );
                    push @all_results, $r;
                }
            }
            else {
                push @all_results, {
                    plate_name          => $plate_name,
                    well_name           => $well_name,
                    well_name_384       => lc to384( $plate_name, $well_name ),
                    num_reads           => $num_reads,
                    num_valid_primers   => 0,
                    valid_primers_score => 0,
                    map { $_ . '_read_length' => $read_length_for->{$plate_name}{$well_name}{$_} }
                        keys %{ $read_length_for->{$plate_name}{$well_name} }
                };
            }
        }
    }

    @all_results = sort {
        $a->{plate_name} cmp $b->{plate_name}
            || lc($a->{well_name}) cmp lc($b->{well_name})
                || $b->{num_valid_primers} <=> $a->{num_valid_primers}
                    || $b->{valid_primers_score} <=> $a->{valid_primers_score};
    } @all_results;

    return \@all_results;
}

1;

__END__
