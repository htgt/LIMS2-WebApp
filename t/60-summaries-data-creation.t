#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($FATAL);
}

use LIMS2::Test;
use Test::Most; # => 6;
use LIMS2::SummaryGeneration::SummariesWellDescend;

# Force reload of fixture data
reload_fixtures;

# Design well ids used:
# 1844 - basic example with 2 trails (one DESIGN to two INT's)
# 930  - heterozygous example with DESIGN->INT->FINAL->DNA->EP->EP_PICK->FP - 49 rows total
# 935  - homozygous example with two branches:
#        DESIGN->INT->FINAL->DNA->EP->SEP->SEP_PICK->SFP
#    and DESIGN->INT->FINAL->DNA->SEP->SEP_PICK->SFP      - 192 rows total

# hash of design wells where expecting clean successful inserts
my %wells_expecting_success = (
    # A design well id    And the expected results; exit code, deletes, inserts, fails.
    1844                 => [0,undef,0,2,0], 
    1847                 => [0,undef,0,10,0],
    930                  => [0,undef,0,49,0],
    935                  => [0,undef,0,192,0],

);

# hash of design wells where expecting other behaviour
my %wells_expecting_other_behaviour = (
    # A design well id    And the expected results; exit code, deletes, inserts, fails.
    935                  => [0,undef,192,192,0], # test deletes
    1                    => [1,"Message",undef,undef,undef], # unknown well to test error handling

);

# determine total count of tests
plan tests => (keys(%wells_expecting_success) * 7) + (keys(%wells_expecting_other_behaviour) * 7);

# loop of tests expected to be successful
while( my($design_well_id, $expected_results) = each %wells_expecting_success ) {
	
    my $results = LIMS2::SummaryGeneration::SummariesWellDescend::generate_summary_rows_for_design_well($design_well_id);

    my $exit_code = $results->{exit_code};

    ok( defined $results,                "Returned results hash defined for design well id : ".$design_well_id );
    ok( defined $results->{exit_code},   "Returned exit code defined for design well id : ".$design_well_id );

    is( $results->{exit_code},      $expected_results->[0],     "Exit code for design well id : ".$design_well_id );
    ok( (( defined $expected_results->[1] ) && ( defined $results->{error_msg} ))
        ||
        (( not defined $expected_results->[1] ) && ( not defined $results->{error_msg} ))
        ,   "Error message for design well id : ".$design_well_id
    );
    is( $results->{count_deletes},  $expected_results->[2],     "Count of 'deletes' for design well id : ".$design_well_id );
    is( $results->{count_inserts},  $expected_results->[3],     "Count of 'inserts' for design well id : ".$design_well_id );
    is( $results->{count_fails},    $expected_results->[4],     "Count of 'fails' for design well id : ".$design_well_id );

}

# loop of tests to test error handling and other activity
while( my($design_well_id2, $expected_results2) = each %wells_expecting_other_behaviour ) {
	
    my $results2 = LIMS2::SummaryGeneration::SummariesWellDescend::generate_summary_rows_for_design_well($design_well_id2);

    my $exit_code = $results2->{exit_code};

    ok( defined $results2,                "Returned results hash defined for design well id : ".$design_well_id2 );
    ok( defined $results2->{exit_code},   "Returned exit code defined for design well id : ".$design_well_id2 );

    is( $results2->{exit_code},      $expected_results2->[0],     "Exit code for design well id : ".$design_well_id2 );
    ok( (( defined $expected_results2->[1] ) && ( defined $results2->{error_msg} ))
        ||
        (( not defined $expected_results2->[1] ) && ( not defined $results2->{error_msg} ))
        ,   "Error message for design well id : ".$design_well_id2 
    );
    is( $results2->{count_deletes},  $expected_results2->[2],     "Count of 'deletes' for design well id : ".$design_well_id2 );
    is( $results2->{count_inserts},  $expected_results2->[3],     "Count of 'inserts' for design well id : ".$design_well_id2 );
    is( $results2->{count_fails},    $expected_results2->[4],     "Count of 'fails' for design well id : ".$design_well_id2 );

}

done_testing();
