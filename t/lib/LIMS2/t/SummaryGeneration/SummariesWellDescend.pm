package LIMS2::t::SummaryGeneration::SummariesWellDescend;
use base qw(Test::Class);
use Test::Most;
use LIMS2::SummaryGeneration::SummariesWellDescend;

use LIMS2::Test model => { classname => __PACKAGE__ };
use strict;

## no critic

=head1 NAME

LIMS2/t/SummaryGeneration/SummariesWellDescend.pm - test class for LIMS2::SummaryGeneration::SummariesWellDescend

See also SummariesWellDescendLegacy test module which tests trails loaded from the legacy fixture data sql file 

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
    Log::Log4perl->easy_init($DEBUG);
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

sub all_tests  : Tests
{

    # Test gibson/crispr well trails which use data from
    # root/static/test/fixtures/LIMS2/t/SummaryGeneration/SummariesWellDescend/
    my %gibson_wells_expecting_success = (
    # A design well id    And the expected results; exit code, deletes, inserts, fails.	
        357575  => [0,undef,0,2,0],
        357579  => [0,undef,0,1,0],
        357587  => [0,undef,0,1,0],
    );
    test_success(\%gibson_wells_expecting_success);

    ## See also SummariesWellDescendLegacy test module which tests trails loaded from 
    ## the legacy fixture data sql file 
}

sub test_success{
    my ($hash) = @_;
    my %wells_expecting_success = %{ $hash };
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
    return;
}
=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

