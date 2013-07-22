package LIMS2::Model::Util::QCResults;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::QCResults::VERSION = '0.089';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            retrieve_qc_run_results
            retrieve_qc_run_results_fast
            retrieve_qc_run_summary_results
            retrieve_qc_run_seq_well_results
            retrieve_qc_alignment_results
            retrieve_qc_seq_read_sequences
            retrieve_qc_eng_seq_sequence
            build_qc_runs_search_params
            infer_qc_process_type
            )
    ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use Bio::SeqIO;
use IO::String;
use Try::Tiny;
use List::Util qw(sum);
use List::MoreUtils qw(uniq);
use LIMS2::Exception::Validation;
use LIMS2::Model::Util::WellName qw ( to384 );
use HTGT::QC::Config;
use HTGT::QC::Util::Alignment qw( alignment_match );
use HTGT::QC::Util::CigarParser;
use LIMS2::Util::Solr;
use JSON qw( decode_json );
use Data::Dumper;

sub retrieve_qc_run_results {
    my $qc_run = shift;
#print "running retrieve_qc_run_results\n";
    my $expected_design_loc = _design_loc_for_qc_template_plate($qc_run);
    my @qc_seq_wells        = $qc_run->qc_run_seq_wells( {},
        { prefetch => ['qc_test_results'] } );

    my @qc_run_results = map { @{ _parse_qc_seq_wells( $_, $expected_design_loc, $qc_run ) } } @qc_seq_wells;

    @qc_run_results = sort {
               $a->{plate_name} cmp $b->{plate_name}
            || lc( $a->{well_name} ) cmp lc( $b->{well_name} )
            || $b->{num_valid_primers} <=> $a->{num_valid_primers}
            || $b->{valid_primers_score} <=> $a->{valid_primers_score};
    } @qc_run_results;

    return \@qc_run_results;
}

#this is functionally the same as retrieve_qc_run_results but with raw sql so pages don't time out.
#eventually this should replace retrive_qc_run_results
sub retrieve_qc_run_results_fast {
    my ( $qc_run, $schema ) = @_;

    my $expected_design_loc = _design_loc_for_qc_template_plate($qc_run);

    #query to fetch all the data we need. we need left joins on alignments/test_results/engseqs
    #because failed wells don't get a qc_test_result or qc_alignment, but we still need to show them.
    #note that there can be multiple qc_test_results for a single seq well.
    my $sql = <<'EOT';
select qc_alignments.qc_eng_seq_id as qc_alignment_eng_seq_id, qc_eng_seqs.id as qc_eng_seq_id, qc_eng_seqs.params as params, 
qc_run_seq_wells.plate_name, qc_run_seq_wells.well_name, qc_test_results.pass as overall_pass, 
qc_seq_reads.primer_name, qc_alignments.score, qc_alignments.pass primer_valid, 
qc_alignments.qc_run_id alignment_qc_run_id
from qc_runs 
join qc_run_seq_wells on qc_run_seq_wells.qc_run_id = qc_runs.id
left join qc_test_results on qc_test_results.qc_run_seq_well_id = qc_run_seq_wells.id
join qc_run_seq_well_qc_seq_read on qc_run_seq_well_qc_seq_read.qc_run_seq_well_id = qc_run_seq_wells.id
join qc_seq_reads on qc_seq_reads.id = qc_run_seq_well_qc_seq_read.qc_seq_read_id
left join qc_eng_seqs on qc_eng_seqs.id = qc_test_results.qc_eng_seq_id
left join qc_alignments on qc_alignments.qc_seq_read_id = qc_seq_reads.id and qc_eng_seqs.id = qc_alignments.qc_eng_seq_id
where qc_runs.id = ?
order by plate_name, well_name, qc_eng_seq_id;
EOT

    #we need this to convert MGI accession ids -> marker symbols
    my $solr = LIMS2::Util::Solr->new;

    my @qc_run_results;
    $schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $sth = $dbh->prepare( $sql );
            $sth->execute( $qc_run->id );

            my $r = $sth->fetchrow_hashref;
            while ( $r ) {
                my $plate_name = $r->{plate_name};
                my $well_name  = $r->{well_name};
                my $eng_seq_id = $r->{qc_eng_seq_id};

                my $eng_seq_params = decode_json( $r->{params} || "{}" );

                my %result = (
                    plate_name         => $plate_name,
                    well_name          => lc $well_name,
                    well_name_384      => lc to384( $plate_name, $well_name ),
                    design_id          => $eng_seq_params->{ design_id },
                    expected_design_id => $expected_design_loc->{ uc $well_name },
                    gene_symbol        => '-',
                    pass               => $r->{overall_pass},
                    primers            => []
                );

                #attempt to get a marker symbol if we have a design id.
                #to do that we first get the mgi accession id, then use that as a lookup in the solr
                if ( defined $eng_seq_params->{ design_id } ) {
                    my $design = $schema->resultset('Design')->find( {
                        id => $eng_seq_params->{ design_id }
                    } );

                    #we do this in a try just in case the design doesn't exist.
                    try {
                        #force the arrayref we get back from solr into an array so it can be appended,
                        #and extract just the marker symbol from the hashref returned by solr.
                        my @genes = map { $_->{marker_symbol} }
                                        map { @{ $solr->query( [ mgi_accession_id => $_->gene_id ] ) } }
                                            $design->genes;
                        #there could be more than one, if so we just display them all
                        $result{gene_symbol} = join ", ", @genes;
                    }
                }

                #aggregate the primers into our hash, making sure that we only do this for results
                #with the same eng seq id (IF we got one), so that we get separate entries for different
                #qc test results.
                my $r_updated = 0;
                while ( $r and $r->{plate_name}    eq $plate_name
                           and $r->{well_name}     eq $well_name
                           and (! defined $eng_seq_id || $r->{qc_eng_seq_id} eq $eng_seq_id) ) {
                    #score, pass and qc_run_id will be empty for rows with no alignments
                    #i.e. those that didn't have any valid reads
                    my %primer = (
                        name      => $r->{primer_name},
                        score     => $r->{score} || 0, #0 instead of undef so the sum still works
                        pass      => $r->{primer_valid},
                        qc_run_id => $r->{alignment_qc_run_id},
                    );

                    $r = $sth->fetchrow_hashref;
                    $r_updated = 1;

                    #skip alignments that aren't for this run (not all alignments have a qc_run_id)
                    if ( defined $primer{qc_run_id} ) {
                        next unless $primer{qc_run_id} eq $qc_run->id;
                    }

                    push @{ $result{primers} }, \%primer;
                }

                #make sure we don't loop infinitely.
                unless ( $r_updated ) {
                    $r = $sth->fetchrow_hashref;
                }

                #before this was just the number of seq reads,
                #which is functionally the same as the number of primers
                $result{num_reads} = scalar @{ $result{primers} };

                #we allow duplicate primers so as not to misreport broken runs
                my @valid_primers = sort { $a->{name} cmp $b->{name} }
                                        grep { $_->{pass} }
                                            @{ $result{primers} };

                $result{valid_primers}       = [ map { $_->{name} } @valid_primers ];
                $result{num_valid_primers}   = scalar @valid_primers || undef;
                $result{score}               = sum( 0, map { $_->{score} } @{ $result{primers} } ) || undef;
                $result{valid_primers_score} = sum( 0, map { $_->{score} } @valid_primers ) || undef;

                push @qc_run_results, \%result;
            }
        }
    );

    @qc_run_results = sort {
               $a->{plate_name}          cmp $b->{plate_name}
            || lc( $a->{well_name} )     cmp lc( $b->{well_name} )
            || $b->{num_valid_primers}   <=> $a->{num_valid_primers}
            || $b->{valid_primers_score} <=> $a->{valid_primers_score};
    } @qc_run_results;

    return \@qc_run_results;
}

sub retrieve_qc_run_summary_results {
    my ( $qc_run ) = @_;

    my $results = retrieve_qc_run_results($qc_run);

    my $template_well_rs = $qc_run->qc_template->qc_template_wells;

    my @summary;
    my %seen_design;

    while ( my $template_well = $template_well_rs->next ) {
        next
            unless $template_well->design_id
                and not $seen_design{ $template_well->design_id }++;

        my %s = (
            design_id   => $template_well->design_id,
            gene_symbol => '-',
        );

        my @results = reverse sort {
                   ( $a->{pass} || 0 ) <=> ( $b->{pass} || 0 )
                || ( $a->{num_valid_primers}   || 0 ) <=> ( $b->{num_valid_primers}   || 0 )
                || ( $a->{valid_primers_score} || 0 ) <=> ( $b->{valid_primers_score} || 0 )
                || ( $a->{score}               || 0 ) <=> ( $b->{score}               || 0 )
                || ( $a->{num_reads}           || 0 ) <=> ( $b->{num_reads}           || 0 )
            }
            grep { $_->{design_id} and $_->{design_id} == $template_well->design_id } @{$results};

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
    my ( $qc_run_id, $seq_well ) = @_;

    my @seq_reads = $seq_well->qc_seq_reads;

    unless (@seq_reads) {
        LIMS2::Exception::Validation->throw(
            'No sequence reads for qc seq well ' . $seq_well->plate_name . $seq_well->well_name );
    }

    #
    # NOTE 
    # until all legacy data is updated we have to allow a null qc_run_id.
    # if its null we just allow it as we can't know which run it belongs to.
    # this method will return ALL alignments if it can't find any linked ones
    #
    my @qc_alignments = map { $_->alignments_for_run( $qc_run_id ) } @seq_reads;

    my @qc_results;
    for my $test_result ( $seq_well->qc_test_results ) {
        my %result;
        $result{design_id}         = $test_result->qc_eng_seq->design_id;
        $result{score}             = $test_result->score;
        $result{pass}              = $test_result->pass;
        $result{qc_test_result_id} = $test_result->id;
        $result{alignments}
            = [ grep { $_->qc_eng_seq_id == $test_result->qc_eng_seq->id } @qc_alignments ];
        push @qc_results, \%result;
    }

    return ( \@seq_reads, \@qc_results );
}

sub retrieve_qc_alignment_results {
    my ( $eng_seq_builder, $qc_alignment ) = @_;

    my $qc_eng_seq     = $qc_alignment->qc_eng_seq->as_hash;
    my $eng_seq_method = $qc_eng_seq->{eng_seq_method};
    my $target         = $eng_seq_builder->$eng_seq_method( $qc_eng_seq->{eng_seq_params} );
    my $query          = $qc_alignment->qc_seq_read->bio_seq;
    my $cigar
        = HTGT::QC::Util::CigarParser->new( strict_mode => 0 )->parse_cigar( $qc_alignment->cigar );

    my $match
        = alignment_match( $query, $target, $cigar, $cigar->{target_start}, $cigar->{target_end} );

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
    unless (@seq_reads) {
        LIMS2::Exception::Validation->throw(
            'No sequence reads for qc seq well ' . $seq_well->plate_name . $seq_well->well_name );
    }

    my $params = _validated_download_seq_params($format);

    my $filename = 'seq_reads_' . $seq_well->plate_name . $seq_well->well_name . $params->{suffix};

    my $formatted_seq;
    my $seq_io
        = Bio::SeqIO->new( -fh => IO::String->new($formatted_seq), -format => $params->{format} );

    for my $seq_read (@seq_reads) {
        $seq_io->write_seq( $seq_read->bio_seq );
    }

    return ( $filename, $formatted_seq );
}

sub retrieve_qc_eng_seq_sequence {
    my ( $eng_seq_builder, $qc_test_result, $format ) = @_;

    my $qc_eng_seq_params = $qc_test_result->qc_eng_seq->as_hash;
    my $eng_seq_method    = $qc_eng_seq_params->{eng_seq_method};
    my $qc_eng_seq = $eng_seq_builder->$eng_seq_method( $qc_eng_seq_params->{eng_seq_params} );

    my $params = _validated_download_seq_params($format);

    my $filename = $qc_eng_seq->display_id . $params->{suffix};

    my $formatted_seq;
    Bio::SeqIO->new(
        -fh     => IO::String->new($formatted_seq),
        -format => $params->{format}
    )->write_seq($qc_eng_seq);

    return ( $filename, $formatted_seq );
}

sub _validated_download_seq_params {
    my ($format) = @_;

    my %params = ( format => 'genbank', );

    const my %SUFFIX_FOR => ( genbank => '.gbk', fasta => '.fasta' );

    if ($format) {
        $format =~ s/^\s+//;
        $format =~ s/\s+$//;
        $format = lc($format);
        if ( exists $SUFFIX_FOR{$format} ) {
            $params{format} = $format;
        }
    }

    $params{suffix} = $SUFFIX_FOR{ $params{format} };

    return \%params;
}

sub _design_loc_for_qc_template_plate {
    my ($qc_run) = @_;
    my %design_loc_for;
    my @qc_template_wells
        = $qc_run->qc_template->qc_template_wells( {}, { prefetch => ['qc_eng_seq'] } );

    for my $well ( map { $_->as_hash } @qc_template_wells ) {
        if ( exists $well->{eng_seq_params}{design_id} ) {
            $design_loc_for{ $well->{name} } = $well->{eng_seq_params}{design_id};
        }
    }

    return \%design_loc_for;
}

sub _parse_qc_seq_wells {
    my ( $qc_seq_well, $expected_design_loc, $qc_run ) = @_;

    my $plate_name      = $qc_seq_well->plate_name;
    my $well_name       = lc( $qc_seq_well->well_name );

    my @qc_test_results = $qc_seq_well->qc_test_results;
    my @qc_seq_reads    = $qc_seq_well->qc_seq_reads( {},
        { prefetch => [ { qc_alignments => 'qc_alignment_regions' } ] } );
    my $num_reads = uniq map { $_->primer_name } @qc_seq_reads;

    my %result = (
        plate_name         => $plate_name,
        well_name          => $well_name,
        well_name_384      => lc to384( $plate_name, $well_name ),
        expected_design_id => $expected_design_loc->{ uc $well_name },
        gene_symbol        => '-', #TODO add gene symbol info once designs imported to lims2
        num_reads          => $num_reads
    );

    return _no_results_for_seq_well( \%result, \@qc_seq_reads )
        unless @qc_test_results;

    _get_primers_for_seq_well( \@qc_seq_reads, \%result );


    #
    # NOTE
    # alignments for run will return all qc alignments for a seq read if it is old
    # qc data which doesnt have a run attached to an alignment
    # 

    my @qc_alignments = map { $_->alignments_for_run( $qc_run->id ) } @qc_seq_reads;

    my @test_results;

    for my $qc_test_result ( $qc_seq_well->qc_test_results ) {
        my %test_result = %result;

        $test_result{score}     = $qc_test_result->score;

        my @alignments = grep { $_->qc_eng_seq_id == $qc_test_result->qc_eng_seq->id } @qc_alignments;
        my @valid_alignments = grep { $_->pass } @alignments;

        $test_result{valid_primers} = [ sort { $a cmp $b } map { $_->primer_name }  @valid_alignments ];
        $test_result{num_valid_primers} = scalar @valid_alignments;
        $test_result{valid_primers_score} = sum( 0, map { $_->score } @valid_alignments );

        $test_result{pass}      = $qc_test_result->pass;
        $test_result{design_id} = $qc_test_result->qc_eng_seq->design_id;;

        push @test_results, \%test_result;
    }

    return \@test_results;
}

sub _no_results_for_seq_well {
    my ( $result, $qc_seq_reads ) = @_;

    $result->{num_valid_primers} = 0;
    $result->{valid_primer_score} = 0;
    for my $qc_seq_read ( @{ $qc_seq_reads } ) {
        my $primer_name = $qc_seq_read->primer_name;
        $result->{ $primer_name . '_read_length' } = $qc_seq_read->length;
    }

    return [ $result ];
}

sub _get_primers_for_seq_well {
    my ( $qc_seq_reads, $result ) = @_;
    my %primers;

    for my $seq_read ( @{$qc_seq_reads} ) {
        for my $alignment ( $seq_read->qc_alignments ) {
            my $primer_name = $alignment->primer_name;
            $primers{$primer_name}{pass}     = $alignment->pass;
            $primers{$primer_name}{score}    = $alignment->score;
            $primers{$primer_name}{features} = $alignment->features;
            $primers{$primer_name}{target_align_length}
                = abs( $alignment->target_end - $alignment->target_start );
            $primers{$primer_name}{read_length} = $seq_read->length;

            $primers{$primer_name}{regions} = _parse_alignment_region($alignment);
        }
    }

    while ( my ( $primer_name, $primer ) = each %primers ) {
        $result->{ $primer_name . '_pass' }                = $primer->{pass};
        $result->{ $primer_name . '_critical_regions' }    = $primer->{regions};
        $result->{ $primer_name . '_target_align_length' } = $primer->{target_align_length};
        $result->{ $primer_name . '_score' }               = $primer->{score};
        $result->{ $primer_name . '_features' }            = $primer->{features};
        $result->{ $primer_name . '_read_length' }         = $primer->{read_length};
    }

    return;
}

sub _parse_alignment_region {
    my $alignment = shift;

    my @regions;
    for my $region ( $alignment->qc_alignment_regions ) {
        push @regions,
            $region->name . ': ' . $region->match_count . '/' . $region->length . $region->pass
            ? 'pass'
            : 'fail';
    }

    return join( q{,}, @regions );
}

sub build_qc_runs_search_params {
    my ( $params ) = @_;

    my %search = (
        'me.upload_complete'        => 't',
        'qc_seq_project.species_id' => $params->{species_id}
    );

    unless ( $params->{show_all} ) {
        if ( $params->{sequencing_project} ) {
            $search{'qc_run_seq_projects.qc_seq_project_id'} = $params->{sequencing_project};
        }
        if ( $params->{template_plate} ) {
            $search{'qc_template.name'} = $params->{template_plate};
        }
        if ( $params->{profile} and $params->{profile} ne '-' ) {
            $search{'me.profile'} = $params->{profile};
        }
    }

    return \%search;
}

sub infer_qc_process_type{
	my ($params) = @_;

	my $process_type;
	my $reagent_count = 0;

	$reagent_count++ if $params->{cassette};
	$reagent_count++ if $params->{backbone};

    # Infer process type from combination of reagents
    if ($reagent_count == 0){
        $process_type = $params->{recombinase} ? 'recombinase'
            	                               : 'rearray' ;
    }
    elsif ($reagent_count == 1){
        $process_type = '2w_gateway';
    }
    else{
        $process_type = '3w_gateway';
    }
    return $process_type;
}
1;

__END__
