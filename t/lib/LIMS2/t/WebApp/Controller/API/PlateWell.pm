package LIMS2::t::WebApp::Controller::API::PlateWell;
use base qw(Test::Class);
use Test::Most;
use LIMS2::WebApp::Controller::API::PlateWell;

use LIMS2::Test;
use File::Temp ':seekable';
use JSON;

=head1 NAME

LIMS2/t/WebApp/Controller/API/PlateWell.pm - test class for LIMS2::WebApp::Controller::API::PlateWell

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

sub all_tests  : Test(38)
{

    my $mech = mech();


    my $plate = 'SEP0006';
    my $species = 'Mouse';

    note( 'Testing genotyping qc contoller' );

    $mech->get_ok('/api/well/genotyping_qc?plate_name='.$plate,
		 {'content-type' => 'application/json'} );

    ok my $json = decode_json($mech->content), 'can decode json response';

    my $well_data = $json->[0];
    my @well_list = ( $well_data->{'id'});
    is $well_list[0], 1621, 'well id is correct';
    is $well_data->{'plate_name'}, $plate, 'wells are from correct plate';

    ok exists($well_data->{'lacz#confidence'}), 'lacz confidence retrieved';
    is $well_data->{'lacz#confidence'}, '>0.98', 'lacz confidence level is correct';
    $mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		 {'content-type' => 'application/json', 'content' => '{"lacz#confidence":">0.96"}'},
		 );

    note('Testing update of confidence value');
    {   
	ok my ($new_well_data) = model->get_genotyping_qc_well_data( \@well_list, $plate, $species ), 'retrieved new well genotyping data';
	is $new_well_data->{'lacz#confidence'}, '>0.96', 'lacz revised confidence level is correct';
    }

    note('Testing reset of assay call value');
    {   
	ok exists($well_data->{'lacz#call'}), 'lacz call retrieved';
	is $well_data->{'lacz#call'}, 'passb', 'lacz call is correct';
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"lacz#call":"reset"}'},
		     );
	ok my ($new_well_data) = model->get_genotyping_qc_well_data( \@well_list, $plate, $species ), 'retrieved fresh well genotyping data';
	is ($new_well_data->{'lacz#call'}, undef, 'lacz call is now undefined') ;
    }

    note("Testing update of assay to 'na'");
    {   
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"lacz#call":"na"}'},
	);
	ok my ($new_well_data) = model->get_genotyping_qc_well_data( \@well_list, $plate, $species ), 'retrieved fresh well genotyping data';
	is ($new_well_data->{'lacz#call'}, 'na', 'lacz call is now na') ;
    }

    note("Testing update of assay to 'pass' in violation of ranking rule");
    {
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"lacz#call":"pass"}'},
	);
	ok my ($new_well_data) = model->get_genotyping_qc_well_data( \@well_list, $plate, $species ), 'retrieved fresh well genotyping data';
	is ($new_well_data->{'lacz#call'}, 'na', 'lacz call is still na') ;
    }

    note("Testing update of assay to 'pass' via reset");
    {
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"lacz#call":"-"}'},
	);
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"lacz#call":"pass"}'},
	);
	ok my ($new_well_data) = model->get_genotyping_qc_well_data( \@well_list, $plate, $species ), 'retrieved fresh well genotyping data';
	is ($new_well_data->{'lacz#call'}, 'pass', 'lacz call is now pass') ;
    }

    note('Testing copy_number and range updates');
    {
	is $well_data->{'lacz#copy_number'}, '1.21', 'intitial lacz copy number is correct';
	is $well_data->{'lacz#copy_number_range'}, '0.05', 'intitial lacz copy number_range is correct';
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"lacz#copy_number":"1.22"}' },
		     );
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"lacz#copy_number_range":"0.06"}' },
		     );

	ok my ($new_well_data) = model->get_genotyping_qc_well_data( \@well_list, $plate, $species ), 'retrieved fresh well genotyping data';
	is ($new_well_data->{'lacz#copy_number'}, '1.22', 'lacz copy_number is now 1.22') ;
	is ($new_well_data->{'lacz#copy_number_range'}, '0.06', 'lacz copy_number_range is now 0.06') ;

    }

    note('Testing well targeting pass update');
    {   
	is $well_data->{'targeting_pass'}, '-', 'targeting pass currently undefined';
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"targeting_pass":"passb"}' },
		     );

	ok my $well_targ_pass = model->retrieve_well_targeting_pass({ id => $well_data->{id} }), 'retrieved new well targeting pass';

	is $well_targ_pass->result, 'passb', 'well targeting pass updated to passb';
    }

    note('Testing gf3 band delete');
    {
	is $well_data->{'gf3'}, 'true', 'gf3 band is true';
	$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
		     {'content-type' => 'application/json', 'content' => '{"gf3":"-"}' },
		     );
	throws_ok {
	    model->retrieve_well_primer_bands({ id => $well_data->{id} });
	} qr/No WellPrimerBands entity found matching/;
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

1;

__END__

