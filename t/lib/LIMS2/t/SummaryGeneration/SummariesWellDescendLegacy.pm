package LIMS2::t::SummaryGeneration::SummariesWellDescendLegacy;
use base qw(Test::Class);
use Test::Most;
use LIMS2::SummaryGeneration::SummariesWellDescend;

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/SummaryGeneration/SummariesWellDescendLegacy.pm - test class for LIMS2::SummaryGeneration::SummariesWellDescend
which uses LEGACY fixture data

See also SummariesWellDescend.pm test module which tests gibson/crispr trails using Human fixture data from
root/static/test/fixtures/LIMS2/t/SummaryGeneration/SummariesWellDescend/

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init($OFF);
};

=head2 before

Code to run before every test

=cut

sub before : Test(setup)
{
    #diag("running before test");
};

=head2 after

Code to run after every test

=cut

sub after  : Test(teardown)
{
    #diag("running after test");
};


=head2 startup

Code to run before all tests for the whole test class

=cut

sub startup : Test(startup)
{
    #diag("running before all tests");
};

=head2 shutdown

Code to run after all tests for the whole test class

=cut

sub shutdown  : Test(shutdown)
{
    #diag("running after all tests");
};

=head2 all_tests

Code to execute all tests

=cut

sub all_tests  : Test(70)
{
    # Force reload of fixture data from root/static/test/fixtures/legacy/10-load-fixture-data.sql
    reload_fixtures;

    # Design well ids used:
    # 1844 - basic example with 2 trails (one DESIGN to two INT's)                   - 2 rows created
    # 1847 - basic example with multiple leaf nodes (two DNA, three EP_PICK, six FP) - 10 rows created
    # 1896 - heterozygous example with:                                              - 1 rows created
    #        DESIGN->INt->INT->FINAL->FINAL_PICK->DNA->FEP->FEPD->FP
    # 1883 and 1877 - homozygous example with two branches:                          - 3 + 1 rows created
    #        DESIGN->INT->INT->FINAL_PICK->DNA->FEP->FEPD(3)->XEP->SEP->SEPD->SFP
    #        DESIGN->INT->INT->FINAL->FINAL_PICK->DNA->(SEP->SEPD->SFP as above)
    # 995  - piq example with:                                                       - 3 rows created
    #        DESIGN->INT->INT->FINAL->FINAL_PICK->DNA->FEP->FEPD->FP->PIQ
    # 930  - heterozygous example with DESIGN->INT->FINAL->DNA->EP->EP_PICK->FP      - 49 rows created
    # 935  - homozygous example with two branches:
    #        DESIGN->INT->FINAL->DNA->EP->SEP->SEP_PICK->SFP
    #    and DESIGN->INT->FINAL->DNA->SEP->SEP_PICK->SFP                             - 192 rows created



    # hash of design wells where expecting clean successful inserts
    my %wells_expecting_success = (
	# A design well id    And the expected results; exit code, deletes, inserts, fails.
	1844                 => [0,undef,0,2,0],
	1847                 => [0,undef,0,10,0],
	1896                 => [0,undef,0,1,0],
	1883                 => [0,undef,0,3,0],
	1877                 => [0,undef,0,1,0],
	995                  => [0,undef,0,3,0],
	930                  => [0,undef,0,49,0],
	935                  => [0,undef,0,192,0],
	);

    # hash of design wells where expecting other behaviour
    my %wells_expecting_other_behaviour = (
	# A design well id    And the expected results; exit code, deletes, inserts, fails.
	935                  => [0,undef,192,192,0], # test deletes
	1                    => [1,"Message",undef,undef,undef], # unknown well to test error handling

	);

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

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

    1;

__END__
