package LIMS2::t::Report::EPSummary;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Report::EPSummary;
use LIMS2::SummaryGeneration::SummariesWellDescend;
use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/Report/EPSummary.pm - test class for LIMS2::Report::EPSummary

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
	# Force reload of fixture data
    #reload_fixtures();

  	my @design_wells = ('1883','1877','935');

  	foreach my $design_well_id (@design_wells) {
  		my $results = LIMS2::SummaryGeneration::SummariesWellDescend::generate_summary_rows_for_design_well($design_well_id);
  		my $exit_code = $results->{exit_code};
  		ok( defined $results,                "Returned results hash defined for design well id : ".$design_well_id );
  		ok( defined $results->{exit_code},   "Returned exit code defined for design well id : ".$design_well_id );
  		is( $results->{exit_code},      0,     "Exit code for design well id : ".$design_well_id );
	  }



    #print "Data regeneration completed.\nStarting tests...\n";




    local $TODO = 'Test of LIMS2::Report::EPSummary in development';
    ok(1, "Test of LIMS2::Report::EPSummary");


    note( 'Testing Pipeline Electroporation Summaries' );

    my $species = 'Mouse'; # NB. need to add tests for human reports later

    ok( my $mech = mech(), 'Created mech object, empty front page' );

    # note( 'Testing Pipeline Electroporation Summaries - loading data' );
    #  load some table data here
    # note( 'Testing Pipeline Summary reports - Mouse double-targeted front page' );
    #  Mouse double-targeted - Front page
    $mech->get_ok( '/user/report/sync/EPSummary' , 'Page requested');
    $mech->content_like(qr^<th>Gene</th>
      <th>Project</th>
      <th>ID</th>
      <th>FEPD Targeted Clones</th>
      <th>SEPD Targeted Clone</th>
      <th>1st allele targeting design ID</th>
      <th>1st allele targeting drug resistance</th>
      <th>1st allele targeting promotor</th>
      <th>1st allele targeting vector plate</th>
      <th>FEPD Number</th>
      <th>2nd allele targeting design ID</th>
      <th>2nd allele targeting drug resistance</th>
      <th>2nd allele targeting promotor</th>
      <th>2nd allele targeting vector plate</th>
      <th>SEPD Number</th>^, 'Checked header');
 
    $mech->content_like(qr'<tbody>
    <tr>
      <td>', 'Rows exist');
    $mech->content_like(qr/Slc4a1/, 'Checked Gene name');
    $mech->content_like(qr/Syboss/, 'Checked Project');
    $mech->content_like(qr/FEP0017_C01/, 'Checked plate_well id');
    $mech->content_like(qr'</td>
      <td>

0

</td>
      <td>

0

</td>', 'Checked FEPD and FEPD targeted clones');
    $mech->content_like(qr'<td>

103

</td>
      <td>

neo

</td>', 'Checked 1st allele design id and resistance');
    $mech->content_like(qr'<td>

L1L2_Bact_P

</td>
      <td>

PATHP0001_A

</td>', 'Checked 1st allele targeting promotor and vector plate');
    $mech->content_like(qr/FEPD0017_4/, 'Checked FEPD number');
    $mech->content_like(qr'<td>

103

</td>
      <td>

bsd

</td>
      <td>

pL1L2_frt_EF1a_BSD_frt_lox

</td>
      <td>

PSABS60002_B

</td>', 'Checked 2nd allele');
    $mech->content_like(qr/<td>

SEPD0017_A/, 'Checked SPED number');
    $mech->content_like(qr'</td>
    </tr>
  </tbody>
</table>', 'Checked table completed successfuly');


    note( 'Testing Electroporation Summary reports - COMPLETED' );

	
};

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

