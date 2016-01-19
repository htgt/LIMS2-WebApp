package LIMS2::t::Report::GeneEPSummary;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Report::GeneEPSummary;
#use LIMS2::SummaryGeneration::SummariesWellDescend;
use LIMS2::Test model => { classname => __PACKAGE__ };

use strict;

## no critic

=head1 NAME

LIMS2/t/Report/GeneEPSummary.pm - test class for LIMS2::Report::GeneEPSummary

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

=head2 all_tests

Code to execute all tests

=cut

sub a_tests  : Test(10)
{
    ok(1, "Test of LIMS2::Report::GeneEPSummary");
    my $design_id = 1002362;
    ok my $GeneEPSummary = LIMS2::Report::GeneEPSummary->new('model' => model, 'species' => 'Human' ), 'GeneEPSummary object created';

    ok my $design_summary_rs =  $GeneEPSummary->design_summary( $design_id ), 'Created design summary resultset';
    is $design_summary_rs->count, 21, 'correct number of rows returned';
    ok my $dna_wells_string = $GeneEPSummary->final_dna_wells( $design_summary_rs ), 'dna wells string generated';
    is $dna_wells_string, 'HFPDNA0001_W_1[B05], HFPQ0001_Z_1[B05]', 'dna wells string content';

    ok my $crispr_ep_wells_string = $GeneEPSummary->crispr_ep_wells( $design_summary_rs ), 'crispr ep wells string generated';
    is $crispr_ep_wells_string, 'None', 'crispr ep wells string content';

    ok my $ep_pick_wells_string = $GeneEPSummary->ep_pick_wells( $design_summary_rs ), 'ep pick wells string generated';
    is $ep_pick_wells_string, 'None', 'ep pick wells string content';
}

sub b_tests  : Test(9)
{
    my $design_id = 3321;
    ok my $GeneEPSummary = LIMS2::Report::GeneEPSummary->new('model' => model, 'species' => 'Human' ), 'GeneEPSummary object created';

    ok my $design_summary_rs =  $GeneEPSummary->design_summary( $design_id ), 'Created design summary resultset';
    is $design_summary_rs->count, 237, 'correct number of rows returned';
    ok my $dna_wells_string = $GeneEPSummary->final_dna_wells( $design_summary_rs ), 'dna wells string generated';
    is $dna_wells_string, 'None', 'dna wells string content';

    ok my $crispr_ep_wells_string = $GeneEPSummary->crispr_ep_wells( $design_summary_rs ), 'crispr ep wells string generated';
    is $crispr_ep_wells_string, 'HUEP0[B01], HUEP0002[A01], HUEP0004[A01], HUEP0005[A01], HUEP0005[A02], HUEP0005[B01], HUEP0005[B02], HUEP0005[C01], HUEP0005[D01], HUEP0005[E01], HUEP0006[C01]', 'crispr ep wells string content';

    ok my $ep_pick_wells_string = $GeneEPSummary->ep_pick_wells( $design_summary_rs ), 'ep pick wells string generated';
    is $ep_pick_wells_string, 'HUEPD0002_1[B03], HUEPD0002_1[C03], HUEPD0002_1[E03], HUEPD0002_1[G04], HUEPD0005_1[A01], HUEPD0005_1[B04], HUEPD0005_1[B06], HUEPD0005_1[E01], HUEPD0005_1[E02], HUEPD0005_1[E04], HUEPD0005_1[G01], HUEPD0005_1[G05], HUEPD0005_1[H06]', 'ep pick wells string content';

}

=head
sub c_tests : Test(2)
{
    my $design_id = 1002379;
    ok my $GeneEPSummary = LIMS2::Report::GeneEPSummary->new('model' => model, 'species' => 'Human' ), 'GeneEPSummary object created';
    ok my $crispr_wells = $GeneEPSummary->crispr_acc_wells( $design_id ), 'retrieve crispr wells for design id';
}
=cut
=head2 BEGIN

Loading other test classes at compile time

=cut

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
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

=head1 AUTHOR

D J Parry-Smith

=cut

## use critic

1;

__END__

