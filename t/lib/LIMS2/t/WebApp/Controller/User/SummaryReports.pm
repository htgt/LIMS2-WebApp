package LIMS2::t::WebApp::Controller::User::SummaryReports;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::User::SummaryReports;

use LIMS2::Test;
use File::Temp ':seekable';
use JSON;
use LIMS2::SummaryGeneration::SummariesWellDescend;

use strict;

## no critic

=head1 NAME

LIMS2/t/WebApp/Controller/User/SummaryReports.pm - test class for LIMS2::WebApp::Controller::User::SummaryReports

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
    Log::Log4perl->easy_init( $FATAL );
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
    note( 'Testing Pipeline Summary reports' );

    my $species = 'Mouse'; # NB. need to add tests for human reports later

    ok( my $mech = mech(), 'Created mech object, empty front page' );

    note( 'Testing Pipeline Summary reports - loading data' );
    # load some table data here

    ok my $test_data= test_data( '70-pipeline_summary_reports_data.yaml' ), 'fetching test data yaml file should succeed';
    {
	# fetch project data from yaml
	ok my $project_rs = model('Golgi')->schema->resultset( 'Project' ),
	    'fetching resultset for table projects should succeed';

	isa_ok $project_rs, 'DBIx::Class::ResultSet';

	ok my $projects = $test_data->{ 'projects' }, 'fetching projects test data from yaml should succeed';

	# insert each project row
	for my $project ( @$projects ) {
        if ($project->{gene_id} eq 'MGI:1914632') {
            my $project = $project_rs->find({ gene_id => $project->{gene_id} });
            ok my $project_deleted = model('Golgi')->delete_project({ id => $project->id }), 'project should be deleted from DB';
        }
	    ok my $project_inserted = $project_rs->create( $project ), 'project should be inserted into DB';
        ok model('Golgi')->add_project_sponsor({
                project_id => $project_inserted->id,
                sponsor_id => 'Syboss',
            }), 'sponsor added to project';
        ok my ($sponsor) = $project_inserted->sponsor_ids, 'project sponsor found';
        is $sponsor, 'Syboss', 'project sponsor correct';

        ok model('Golgi')->update_project_sponsors({
                project_id => $project_inserted->id,
                sponsor_list => ['Mutation'],
            }), 'project sponsors updated';
        ok my @new_sponsors = $project_inserted->sponsor_ids, 'project sponsor found';
        is scalar(@new_sponsors), 1, 'project has correct number of sponsors';
        is $new_sponsors[0],'Mutation', 'project sponsor is correct';
	}

	# fetch summaries data from yaml
	ok my $summary_rs = model('Golgi')->schema->resultset( 'Summary' ),
	    'fetching resultset for table summaries should succeed';

	isa_ok $summary_rs, 'DBIx::Class::ResultSet';

	ok my $summaries = $test_data->{ 'summaries' }, 'fetching summaries test data from yaml should succeed';

	# insert each summary row
	for my $summary ( @$summaries ) {
	    ok my $summary_inserted = $summary_rs->create( $summary ), 'summary should be inserted into DB';
	}

    }
=head
    note( 'Testing Pipeline Summary reports - Mouse double-targeted front page' );
    # Mouse double-targeted - Front page
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted' , 'Re-requested Mouse double-targeted front page after loading pipeline test data');

    $mech->content_like(qr/Genes">2</, 'Checked content Genes');
    $mech->content_like(qr/Vectors Constructed">1</, 'Checked content Vectors Constructed');
    $mech->content_like(qr/Vectors Neo and Bsd">1</, 'Checked content Vectors Neo and Bsd');
    $mech->content_like(qr/Vectors Neo">1</, 'Checked content Vectors Neo');
    $mech->content_like(qr/Vectors Bsd">1</, 'Checked content Vectors Bsd');
    $mech->content_like(qr/Valid DNA">1</, 'Checked content Valid DNA');
    $mech->content_like(qr/Valid DNA Neo and Bsd">1</, 'Checked content Valid DNA Neo and Bsd');
    $mech->content_like(qr/Valid DNA Neo">1</, 'Checked content Valid DNA Neo');
    $mech->content_like(qr/Valid DNA Bsd">1</, 'Checked content Valid DNA Bsd');
    $mech->content_like(qr/First Electroporations">1</, 'Checked content First Electroporations');
    $mech->content_like(qr/First Electroporations Neo">1</, 'Checked content First Electroporations Neo');
    $mech->content_like(qr/Second Electroporations">1</, 'Checked content Second Electroporations');
    $mech->content_like(qr/Second Electroporations Bsd">1</, 'Checked content Second Electroporations Bsd');
    $mech->content_like(qr/Accepted Second ES Clones">1</, 'Checked content Accepted Second ES Clones');

    note( 'Testing Pipeline Summary reports - Mouse double-targeted drilldowns' );
    # Mouse double-targeted - Targeted Genes
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Genes' , 'Pipeline drilldowns: Mouse double-targeted - Genes');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Genes');

    # Mouse double-targeted - Vectors
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Vectors Constructed' , 'Pipeline drilldowns: Mouse double-targeted - Vectors Constructed');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors Constructed');

    # Mouse double-targeted - Vectors Neo and Bsd
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Vectors Neo and Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Vectors Neo and Bsd');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors Neo and Bsd');

    # Mouse double-targeted - Vectors Neo
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Vectors Neo' , 'Pipeline drilldowns: Mouse double-targeted - Vectors Neo');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors Neo');

    # Mouse double-targeted - Vectors Bsd
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Vectors Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Vectors Bsd');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors Bsd');

    # Mouse double-targeted - Valid DNA
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Valid DNA' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA');

    # Mouse double-targeted - Valid DNA Neo and Bsd
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Valid DNA Neo and Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA Neo and Bsd');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA Neo and Bsd');

    # Mouse double-targeted - Valid DNA Neo
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Valid DNA Neo' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA Neo');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA Neo');

    # Mouse double-targeted - Valid DNA Bsd
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Valid DNA Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA Bsd');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA Bsd');

    # Mouse double-targeted - First Electroporations
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/First Electroporations' , 'Pipeline drilldowns: Mouse double-targeted - First Electroporations');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown First Electroporations');

    # Mouse double-targeted - First Electroporations Neo
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/First Electroporations Neo' , 'Pipeline drilldowns: Mouse double-targeted - First Electroporations Neo');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown First Electroporations Neo');

    # Mouse double-targeted - Accepted First ES Clones
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Accepted First ES Clones' , 'Pipeline drilldowns: Mouse double-targeted - Accepted First ES Clones');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown First ES Clones');

    # Mouse double-targeted - Second Electroporations
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Second Electroporations' , 'Pipeline drilldowns: Mouse double-targeted - Second Electroporations');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Second Electroporations');

    # Mouse double-targeted - Second Electroporations Bsd
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Second Electroporations Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Second Electroporations Bsd');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Second Electroporations Bsd');

    # Mouse double-targeted - Accepted Second ES Clones
    $mech->get_ok( '/public_reports/sponsor_report/double_targeted/Syboss/Accepted Second ES Clones' , 'Pipeline drilldowns: Mouse double-targeted - Accepted Second ES Clones');
    $mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Second ES Clones');

    note( 'Testing Pipeline Summary reports - Mouse single-targeted drilldowns' );
    # Mouse single-targeted - Front page
    $mech->get_ok( '/public_reports/sponsor_report/single_targeted' , 'Requested Mouse single-targeted front page after loading pipeline test data');

    $mech->content_like(qr/Genes">1</, 'Checked content Genes');
    $mech->content_like(qr/Vectors Constructed">1</, 'Checked content Vectors Constructed');
    # $mech->content_like(qr/Valid DNA">1</, 'Checked content Valid DNA');
    $mech->content_like(qr/Genes Electroporated">1</, 'Checked content Genes Electroporated');
    $mech->content_like(qr/Targeted Genes">1</, 'Checked content Targeted Genes');

    note( 'Testing Pipeline Summary reports - Mouse single-targeted drilldowns' );
    # Mouse single-targeted - Genes
    $mech->get_ok( '/public_reports/sponsor_report/single_targeted/Cre Knockin/Genes' , 'Pipeline drilldowns: Mouse single-targeted - Genes');
    $mech->content_like(qr/>MGI:1095419</, 'Checked content drilldown Genes');

    # Mouse single-targeted - Vectors
    $mech->get_ok( '/public_reports/sponsor_report/single_targeted/Cre Knockin/Vectors Constructed' , 'Pipeline drilldowns: Mouse single-targeted - Vectors Constructed');
    $mech->content_like(qr/>MGI:1095419</, 'Checked content drilldown Vectors Constructed');

    # Mouse single-targeted - Valid DNA
    # $mech->get_ok( '/public_reports/sponsor_report/single_targeted/Cre Knockin/Valid DNA' , 'Pipeline drilldowns: Mouse single-targeted - Valid DNA');
    # $mech->content_like(qr/>MGI:1095419</, 'Checked content drilldown Valid DNA');

    # Mouse single-targeted - Genes Electroporated
    $mech->get_ok( '/public_reports/sponsor_report/single_targeted/Cre Knockin/Genes Electroporated' , 'Pipeline drilldowns: Mouse single-targeted - Genes Electroporated');
    $mech->content_like(qr/>MGI:1095419</, 'Checked content drilldown Genes Electroporated');

    # Mouse single-targeted - Targeted Genes
    $mech->get_ok( '/public_reports/sponsor_report/single_targeted/Cre Knockin/Targeted Genes' , 'Pipeline drilldowns: Mouse single-targeted - Accepted First ES Clones');
    $mech->content_like(qr/>MGI:1095419</, 'Checked content drilldown Targeted Genes');
=cut

    note( 'Testing Pipeline Summary reports - COMPLETED' );

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

