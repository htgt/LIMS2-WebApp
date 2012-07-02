package LIMS2::Model::Util::QC;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( retrieve_qc_run_results retrieve_qc_run_summary_results ) ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use List::Util qw(sum);
use LIMS2::Model::Util::WellName qw ( to384 );
use HTGT::QC::Config;
use HTGT::QC::Config::Profile;

use Smart::Comments;

sub retrieve_qc_run_results {
    my ( $qc_run ) = @_;

    my $expected_design_loc = design_loc_for_qc_template_plate( $qc_run->qc_template );    

    my %read_length_for;
    
    for my $seq_well ( $qc_run->qc_run_seq_wells ) {
        my $plate_name = $seq_well->plate_name;
        my $well_name  = lc($seq_well->well_name);
        for my $seq_read ( $seq_well->qc_seq_reads ) {
            $read_length_for{$plate_name}{$well_name}{$seq_read->primer_name}
                = $seq_read->length;
        }
    }

    my $vector_stage = get_vector_stage( $qc_run );

    %read_length_for = %{ combine_ABRZ_plates( \%read_length_for ) } 
        if $vector_stage eq 'allele';

    my @results;

    for my $qc_test_result ( $qc_run->qc_test_results ) {
        my $seq_well = $qc_test_result->qc_run_seq_well;
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
            num_reads          => scalar( keys %{ $read_length_for{ $plate_name }{ $well_name } } ), #better way to do this
        );

        my %primers;
        for my $seq_read ( $seq_well->qc_seq_reads ) {
            for my $alignment ( $seq_read->qc_alignments ) {
                my $primer_name = $alignment->primer_name;
                $primers{$primer_name}{pass} = $alignment->pass;
                $primers{$primer_name}{score} = $alignment->score;
                $primers{$primer_name}{features} = $alignment->features;
                $primers{$primer_name}{target_align_length}
                    = abs( $alignment->target_end - $alignment->target_start );
                $primers{$primer_name}{read_length} 
                    = $read_length_for{ $plate_name }{ $well_name }{ $primer_name };                    

                my @regions;
                for my $region ( $alignment->qc_alignment_regions ) {
                    push @regions, $region->name . ': ' . $region->match_count 
                        . '/' . $region->length . $region->pass ? 'pass' : 'fail';
                }
                $primers{$primer_name}{regions} = join( q{,}, @regions );
            }
        }

        my @valid_primers = sort { $a cmp $b } grep { $primers{$_}->{pass} } keys %primers;
        $result{valid_primers}       = \@valid_primers;
        $result{num_valid_primers}   = scalar @valid_primers;
        $result{score}               = sum( 0, map $_->{score}, values %primers );
        $result{valid_primers_score} = sum( 0, map $primers{$_}->{score}, @valid_primers );

        while ( my ( $primer_name, $primer ) = each %primers ) {
            $result{ $primer_name . '_pass' }                = $primer->{pass};
            $result{ $primer_name . '_critical_regions' }    = $primer->{regions};
            $result{ $primer_name . '_target_align_length' } = $primer->{target_align_length};
            $result{ $primer_name . '_score' }               = $primer->{score};
            $result{ $primer_name . '_features' }            = $primer->{features};
            $result{ $primer_name . '_read_length' }         = $primer->{read_length};
        }
        push @results, \%result;
    }

    # Merge in the number of primer reads (this has to be done in a
    # separate loop to catch wells with primer reads but no test
    # results)
    
    my @all_results;

    for my $plate_name ( keys %read_length_for ) {
        for my $well_name ( keys %{ $read_length_for{ $plate_name } } ) {
            my $num_reads = scalar( keys %{ $read_length_for{ $plate_name }{ $well_name } } );
            my @these_results = grep { $_->{plate_name} eq $plate_name && $_->{well_name} eq $well_name } @results;
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
                    map { $_ . '_read_length' => $read_length_for{$plate_name}{$well_name}{$_} } keys %{ $read_length_for{$plate_name}{$well_name} }
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

sub design_loc_for_qc_template_plate {
    my ( $template_plate ) = @_;
    my %design_loc_for;

    for my $well ( map { $_->as_hash } $template_plate->qc_template_wells->all ) {
        if ( exists $well->{eng_seq_params}{design_id} ) {
            $design_loc_for{$well->{name}} = $well->{eng_seq_params}{design_id};
        }
    }

    return \%design_loc_for;
}

sub get_vector_stage{
    my ( $qc_run ) = @_;

    my $profile_name = $qc_run->profile;

    my $profile = HTGT::QC::Config->new->profile( $profile_name );

    return $profile->vector_stage;
}

sub combine_ABRZ_plates{
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
                $combined{$plate_name_stem}{$well_name}{$primer_name} = $read_length_for->{$plate_name}{$well_name}{$primer};
            }
        }
    }

    return \%combined;
}

1;

__END__
