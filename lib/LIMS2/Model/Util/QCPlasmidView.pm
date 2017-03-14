package LIMS2::Model::Util::QCPlasmidView;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::QCPlasmidView::VERSION = '0.451';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
            add_display_info_to_qc_results
          )
    ]
};


use Number::Range;
use List::Util qw(sum);
use Bio::Perl qw( revcom );
use Data::Dumper;

sub add_display_info_to_qc_results{
    my ($results, $log, $model) = @_;

    # Set angularplasmid display parameters for each alignment
    foreach my $result (@$results){
        # Allow up to 3 display levels for reads and target region labels to avoid overlap
        my @read_levels = ( Number::Range->new(), Number::Range->new(), Number::Range->new() );
        my @target_region_levels = ( Number::Range->new(), Number::Range->new(), Number::Range->new() );
        my @display_alignments;
        my $alignment_targets = {};
        foreach my $a (@{ $result->{alignments} }){
            my $alignment_result = $model->qc_alignment_result({ qc_alignment_id => $a->id });

            my $params = {
                name => $a->primer_name,
                id => $a->id,
                match_pct => $alignment_result->{match_pct},
            };

            # Start must be before end for display. draw arrow at start or end to indicate read direction.
            if ($a->target_start < $a->target_end){
                $params->{start} = $a->target_start;
                $params->{end} = $a->target_end;
                $params->{arrow} = "arrowendlength='10' arrowendwidth='5' arrowendangle='3'";
            }
            else{
                $params->{start} = $a->target_end;
                $params->{end} = $a->target_start;
                $params->{arrow} = "arrowstartlength='10' arrowstartwidth='5' arrowstartangle='3'";
            }

            $params->{vadjust_level} = _get_vadjust_level($params->{start},$params->{end},\@read_levels);

            unless($params->{vadjust_level}){
                $log->warn("Could not assign read ".$a->primer_name." to display level without overlap");
                # Bung it in level 1
                $params->{vadjust_level} = 1;
            }

            # Set display class to show passes and fails
            # FIXME: should store pass/fail and set class in tt view
            if($a->pass){
                $params->{class} = 'marker_read_align';
            }
            else{
                $params->{class} = 'marker_fail_read_align';
            }

            push @display_alignments, $params;

            # Now find alignment target regions
            my @alignment_regions;
            foreach my $region ($a->qc_alignment_regions){
                my $target_params = {
                    name => $region->name,
                    pass => $region->pass,
                };
                my $target_str = $region->target_str;
                $target_str =~ s/-//g;
                my $start = index($result->{eng_seq}->seq, $target_str);
                if($start == -1){
                    # revcom and try again
                    my $rev_target_str = revcom($target_str)->seq;
                    $start = index($result->{eng_seq}->seq, $rev_target_str);
                }

                if($start > -1){
                    $target_params->{start} = $start;
                    $target_params->{end} = $start + $region->length;
                    $target_params->{vadjust_level} = _get_vadjust_level(
                        $target_params->{start},
                        $target_params->{end},
                        \@target_region_levels,
                        500
                    );
                    unless($target_params->{vadjust_level}){
                        $log->warn("Could not assign target region ".$region->name." to display level without overlap");
                        $target_params->{vadjust_level} = 1;
                    }
                    push @alignment_regions, $target_params;
                }
                else{
                    $log->warn("Region ".$region->name." not found in eng_seq");
                }
            }
            $alignment_targets->{ $a->primer_name } = \@alignment_regions;

        }
        $result->{display_alignments} = \@display_alignments;
        $result->{alignment_targets} = $alignment_targets;
    }
    return;
}

# Inputs:
#  - start coord of feature
#  - end cood of feature
#  - arrayref of levels where each level is a Number::Range
#  - number of bases of padding needed around feature to allow for labels etc (default:0)
#
# Returns a positive integer which can be used as a multiplier when setting the vadjust
# parameter to position the trackmarker or label so they do not overlap
#
# Returns undef if all levels are full
sub _get_vadjust_level{
    my ($start, $end, $levels, $padding) = @_;

    # Add padding to feature position
    $padding ||= 0;
    my $range_start = $start - $padding;
    my $range_end = $end + $padding;

    # Check for overlapping regions and set vadjust level to avoid overlap in display
    # vadjust_level is used as a multiplier so distance between levels is set in view
    my $level = 1;
    foreach my $level_range (@$levels){
        my @in_range_results = $level_range->inrange($range_start..$range_end);
        if(grep { $_==1 } @in_range_results){
            # try the next level
            $level++;
            next();
        }
        else{
            # No overlap, we can display on this level
            # and add this feature to the range
            $level_range->addrange($range_start."..".$range_end);
            return $level;
        }
    }
    return;
}


1;