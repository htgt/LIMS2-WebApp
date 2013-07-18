package LIMS2::t::Model::Util::ComputeAcceptedStatus;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Util::ComputeAcceptedStatus qw(compute_accepted_status);

use LIMS2::Test;

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Util/ComputeAcceptedStatus.pm - test class for LIMS2::Model::Util::ComputeAcceptedStatus

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

sub all_tests  : Test(13)
{
    {
	    note ("Testing has_dna_pass");

	    my $dna_well_params = { well_name => 'D04', plate_name => 'MOHFAQ0001_A_2' };

	    ok my $dna_well = model->retrieve_well( $dna_well_params ),
		'retrieve well from DNA plate';
	    is (compute_accepted_status(model, $dna_well), 1, 'DNA well accepted status true');
	    lives_ok{
		    model->delete_well_dna_status( $dna_well_params )
	    } 'well DNA status deleted';
	    ok $dna_well = model->retrieve_well( $dna_well_params ),
		'retrieve well from DNA plate';
	    is (compute_accepted_status(model, $dna_well), 0, 'DNA well accepted status false');
    }

    {
	    note ("Testing has_recombineering_pass");

	    my $design_well_params = { well_name => 'F02', plate_name => '148'};

	    ok my $design_well = model->retrieve_well( $design_well_params ),
		'retrieve well from design plate';
	is (compute_accepted_status(model, $design_well), 1, 'DESIGN well accepted status true');
	ok my $rec_result = $design_well->recombineering_result( 'rec_result' ),
	    'retrieve rec_result';
	ok $rec_result->update( { result => 'fail' } ), 'rec_result changed to fail';
	ok $design_well = model->retrieve_well( $design_well_params ),
		'retrieve well from design plate';
	    is (compute_accepted_status(model, $design_well), 0, 'DESIGN well accepted status false');
    }

    {
	    note ("Testing compute_accepted_status error");

	    my $ep_well_params = { well_name => 'A01', plate_name => 'FEPD0006_1' };
	    ok my $ep_well = model->retrieve_well( $ep_well_params ),
		'retrieve well from EP_PICK plate';
	    throws_ok{
		    compute_accepted_status(model, $ep_well);
	    } qr/No handler defined/;
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

## use critic

1;

__END__

