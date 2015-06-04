package LIMS2::t::WebApp::Controller::API::AssemblyQc;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::API::AssemblyQc;

# use the same fixture data as the reports because we need an assembly plate
use LIMS2::Test model => { classname => 'LIMS2::t::WebApp::Controller::User::Report' }, 'mech';
use Data::Dumper;

use strict;

## no critic

BEGIN
{
    # compile time requirements
    #{REQUIRE_PARENT}
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
};

sub all_tests  : Test(10)
{
	my $mech = mech();
	my $model = model();

    my $plate = $model->retrieve_plate({ id => 5965 });
	my $well = $plate->wells->first;
	my $well_id = $well->id;
	is $well->assembly_qc_value('CRISPR_LEFT_QC'), undef, 'well has no crispr left assembly qc';

	$mech->get_ok("/api/update_assembly_qc?well_id=$well_id&type=CRISPR_LEFT_QC&value=Good",
		          { 'content-type' => 'application/json'});

    $well->discard_changes();
    is $well->assembly_qc_value('CRISPR_LEFT_QC'),'Good', 'well crispr left assembly qc set to Good';

    $mech->get_ok("/api/update_assembly_qc?well_id=$well_id&type=CRISPR_LEFT_QC&value=Bad",
		          { 'content-type' => 'application/json'});
    $well->discard_changes();
    is $well->assembly_qc_value('CRISPR_LEFT_QC'),'Bad', 'well crispr left assembly qc updated to Bad';

    $mech->get("/api/update_assembly_qc?well_id=$well_id&type=CRISPR_LEFT_QC&value=Unknown",
		        { 'Content-Type' => 'application/json'});
    is $mech->status, 415, 'update fails with unknown value';

    $mech->get("/api/update_assembly_qc?well_id=$well_id&type=UNKNOWN_QC&value=Good",
		        { 'Content-Type' => 'application/json'});
    is $mech->status, 415, 'update fails with unknown QC type';

    $well->discard_changes();
    is $well->assembly_qc_value('CRISPR_LEFT_QC'),'Bad', 'well crispr left assembly qc has not changed';

    $mech->get_ok("/api/update_assembly_qc?well_id=$well_id&type=CRISPR_LEFT_QC",
		          { 'content-type' => 'application/json'});
    $well->discard_changes();
    is $well->assembly_qc_value('CRISPR_LEFT_QC'), undef, 'well crispr left assembly qc has been unset';

}

1;