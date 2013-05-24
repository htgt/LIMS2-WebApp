#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';
use JSON;
use LIMS2::SummaryGeneration::SummariesWellDescend;

note( 'Testing Pipeline Summary reports' );

my $species = 'Mouse'; # NB. need to add tests for human reports later

# Set up test plan
# plan $@
#     ? ( skip_all => 'Test::WWW::Mechanize::Catalyst required' )
#     : ( tests => 20 );

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
        ok my $project_inserted = $project_rs->create( $project ), 'project should be inserted into DB';
    }

    # fetch project_alleles data from yaml
    ok my $project_allele_rs = model('Golgi')->schema->resultset( 'ProjectAllele' ),
        'fetching resultset for table project_alleles should succeed';

    isa_ok $project_allele_rs, 'DBIx::Class::ResultSet';

    ok my $project_alleles = $test_data->{ 'project_alleles' }, 'fetching project alleles test data from yaml should succeed';
 
    # insert each project_alleles row
    for my $project_allele ( @$project_alleles ) {
        ok my $project_allele_inserted = $project_allele_rs->create( $project_allele ), 'project allele should be inserted into DB';
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

note( 'Testing Pipeline Summary reports - Mouse double-targeted front page' );
# Mouse double-targeted - Front page
$mech->get_ok( '/user/double_targeted' , 'Re-requested Mouse double-targeted front page after loading pipeline test data');

$mech->content_like(qr/Targeted Genes">1</, 'Checked content Targeted Genes');
$mech->content_like(qr/Vectors">1</, 'Checked content Vectors');
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
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Targeted Genes' , 'Pipeline drilldowns: Mouse double-targeted - Targeted Genes');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Targeted Genes');

# Mouse double-targeted - Vectors
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Vectors' , 'Pipeline drilldowns: Mouse double-targeted - Vectors');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors');

# Mouse double-targeted - Vectors Neo and Bsd
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Vectors Neo and Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Vectors Neo and Bsd');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors Neo and Bsd');

# Mouse double-targeted - Vectors Neo
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Vectors Neo' , 'Pipeline drilldowns: Mouse double-targeted - Vectors Neo');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors Neo');

# Mouse double-targeted - Vectors Bsd
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Vectors Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Vectors Bsd');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Vectors Bsd');

# Mouse double-targeted - Valid DNA
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Valid DNA' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA');

# Mouse double-targeted - Valid DNA Neo and Bsd
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Valid DNA Neo and Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA Neo and Bsd');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA Neo and Bsd');

# Mouse double-targeted - Valid DNA Neo
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Valid DNA Neo' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA Neo');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA Neo');

# Mouse double-targeted - Valid DNA Bsd
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Valid DNA Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Valid DNA Bsd');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Valid DNA Bsd');

# Mouse double-targeted - First Electroporations
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/First Electroporations' , 'Pipeline drilldowns: Mouse double-targeted - First Electroporations');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown First Electroporations');

# Mouse double-targeted - First Electroporations Neo
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/First Electroporations Neo' , 'Pipeline drilldowns: Mouse double-targeted - First Electroporations Neo');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown First Electroporations Neo');

# Mouse double-targeted - Accepted First ES Clones
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Accepted First ES Clones' , 'Pipeline drilldowns: Mouse double-targeted - Accepted First ES Clones');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown First ES Clones');

# Mouse double-targeted - Second Electroporations
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Second Electroporations' , 'Pipeline drilldowns: Mouse double-targeted - Second Electroporations');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Second Electroporations');

# Mouse double-targeted - Second Electroporations Bsd
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Second Electroporations Bsd' , 'Pipeline drilldowns: Mouse double-targeted - Second Electroporations Bsd');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Second Electroporations Bsd');

# Mouse double-targeted - Accepted Second ES Clones
$mech->get_ok( '/user/view_summary_report/double_targeted/Syboss/Accepted Second ES Clones' , 'Pipeline drilldowns: Mouse double-targeted - Accepted Second ES Clones');
$mech->content_like(qr/>MGI:1914632</, 'Checked content drilldown Second ES Clones');

note( 'Testing Pipeline Summary reports - Mouse single-targeted drilldowns' );
???
done_testing();