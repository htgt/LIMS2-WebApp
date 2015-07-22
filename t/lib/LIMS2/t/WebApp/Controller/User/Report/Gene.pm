package LIMS2::t::WebApp::Controller::User::Report::Gene;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::Report::Gene;
use LIMS2::SummaryGeneration::SummariesWellDescend;
use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/Report/Gene.pm - test class for LIMS2::WebApp::Controller::User::Report::Gene

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
    my @design_wells = ('1883','1877','935');
    foreach my $design_well_id (@design_wells) {
        my $results = LIMS2::SummaryGeneration::SummariesWellDescend::generate_summary_rows_for_design_well($design_well_id);
        my $exit_code = $results->{exit_code};
        ok( defined $results,                "Returned results hash defined for design well id : ".$design_well_id );
        ok( defined $results->{exit_code},   "Returned exit code defined for design well id : ".$design_well_id );
        is( $results->{exit_code},      0,     "Exit code for design well id : ".$design_well_id );
    }

    note( 'Testing Gene Report Summaries' );

    my $species = 'Mouse'; # NB. need to add tests for human reports later

    ok( my $mech = mech(), 'Created mech object, empty front page' );

    $mech->get_ok( 'user/report/gene?gene_id=Brd3' , 'Page requested');

    $mech->content_like(qr'Showing details for Brd3', 'Checked Gene');

    $mech->content_like(qr'>34188</a></td>
              <td>EUCTV3754</td>
              <td>conditional</td>
              <td>unknown</td>
              <td>2007-03-02</td>
              <td>not done</td>
              <td>ENSMUST00000113941</td>
              <td>MGI:1914632</td>', 'Checked Design');

    $mech->content_like(qr'>56</a></td>
              <td>G04</td>
              <td>2007-08-24</td>
              <td>34188</td>
              <td></td>
              <td>no</td>', 'Checked DESIGN');

    $mech->content_like(qr'>MOHPCS0001_A</a></td>
              <td>H02</td>
              <td>2010-03-03</td>
              <td>pR6K_R1R2_ZP</td>
              <td>R3R4_pBR_amp</td>
              <td></td>
              <td>pass</td>
              <td>yes</td>', 'Checked INT');

    $mech->content_like(qr'>MOHSAS0001_A</a></td>
              <td>H02</td>
              <td>2010-03-23</td>
              <td>L1L2_GT2_LacZ_BSD</td>
              <td>R3R4_pBR_amp</td>
              <td>Cre</td>
              <td>pass</td>
              <td>yes</td>', 'Checked FINAL');

    $mech->content_like(qr'>MOHSAQ0001_A_2</a></td>
              <td>H02</td>
              <td>2012-06-15</td>
              <td>_</td>
              <td></td>
              <td></td>
              <td>pass</td>
              <td>no</td>', 'Checked DNA');

    $mech->content_like(qr'>FEP0006</a></td>
              <td>A01</td>
              <td>2012-05-21</td>
              <td>_</td>
              <td>MOHFAQ0001_A_2_H02</td>
              <td></td>
              <td></td>
              <td>no</td>', 'Checked EP');

    $mech->content_like(qr'>XEP0006</a></td>
              <td>C01</td>
              <td>2012-06-15</td>
              <td>
                
                  FEP0006_A01<', 'Checked XEP');

    $mech->content_like(qr'>SEP0006</a></td>
              <td>C01</td>
              <td>2012-06-15</td>
              <td></td>
              <td></td>
              <td>no</td>', 'Checked SEP');

    $mech->content_like(qr'>SEPD0006_1</a></td>
              <td>D01</td>
              <td>2012-07-04</td>
              <td>SEP0006_C01</td>
              <td>no</td>
            </tr>
            <tr>
              <td>SEPD0006_1_D02</td>
              <td>', 'Checked SEP_PICK');

    $mech->content_like(qr'>SFP0001</a></td>
              <td>H07</td>
              <td>2012-07-11</td>
              <td>FEP0006_A01</td>
              <td>SEP0006_C01</td>
              <td>SEPD0006_1_H07</td>
              <td>no</td>
            </tr>
            <tr>
              <td>SFP0001_H08</td>
              <td><a', 'Checked SFP');

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

