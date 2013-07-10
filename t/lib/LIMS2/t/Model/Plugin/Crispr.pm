package LIMS2::t::Model::Plugin::Crispr;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::Crispr;

use LIMS2::Test;
use Data::Dumper;

=head1 NAME

LIMS2/t/Model/Plugin/Crispr.pm - test class for LIMS2::Model::Plugin::Crispr

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

sub all_tests  : Test(58)
{

    note('Testing the Creation crisprs');
    my $create_crispr_data= test_data( 'create_crispr.yaml' );
    my $crispr;
    {   

	ok $crispr = model->create_crispr( $create_crispr_data->{valid_crispr} )
	    , 'can create new crispr';
	is $crispr->crispr_loci_type_id, 'Exonic', '.. crispr type is correct';
	is $crispr->seq, 'ATCGGCACACAGAGAG', '.. crispr seq is correct';

	ok my $locus = $crispr->loci->first, 'can retrieve crispr locus';
	is $locus->assembly_id, 'GRCm38', '.. locus assembly correct';
	is $locus->chr->name, 12, '.. locus chromosome correct';

	ok my $off_targets = $crispr->off_targets, 'can retreive off targets from crispr';
	is $off_targets->count, 2, '.. we have 2 off targets';
	ok my $off_target = $off_targets->find( { crispr_loci_type_id => 'Intronic' } ), 'can grab intron off target';
	is $off_target->assembly_id, 'GRCm38', '.. off target assembly correct';
	is $off_target->build_id, 70, '.. off target build correct';
	is $off_target->chromosome, 11, '.. off target chr correct';
	is $off_target->algorithm, 'strict', '.. off target algorithm correct';

	is $crispr->off_target_summaries->count, 1, 'We have only one off target summary';
	my $off_target_summary = $crispr->off_target_summaries->first;
	is $off_target_summary->algorithm, 'strict', '.. correct algorithm';
	is $off_target_summary->outlier, 0, '.. correct outlier';
	is $off_target_summary->summary, '{Exons: 5, Introns:10, Intergenic: 15}', '.. correct summary';

	throws_ok {
	    model->create_crispr( $create_crispr_data->{species_assembly_mismatch} )
	} qr/Assembly GRCm38 does not belong to species Human/
	    , 'throws error when species and assembly do not match';
    }

    note('Create dupliate crispr with same off target algorithm data' );
    {   
	# with same off target algorithm
	ok my $duplicate_crispr = model->create_crispr(
	    $create_crispr_data->{duplicate_crispr_same_off_target_algorithm} ),
	    'can create dupliate crispr';
	is $duplicate_crispr->id, $crispr->id, 'we have the same crispr';
	ok my $new_off_targets = $duplicate_crispr->off_targets, 'can retrieve new off targets';
	is $new_off_targets->count, 1, '.. only 1 off target now';
	is $new_off_targets->first->chromosome, 15, '.. new off target has right chromosome';
	is $new_off_targets->first->algorithm, 'strict', '.. new off target has same algorithm';

	is $duplicate_crispr->off_target_summaries->count, 1, 'We still only have one off target summary';
	my $off_target_summary = $duplicate_crispr->off_target_summaries->first;
	is $off_target_summary->algorithm, 'strict', '.. correct algorithm';
	is $off_target_summary->outlier, 1, '.. correct outlier';
    }

    note('Create dupliate crispr with different off target algorithm data');
    {   

	ok my $duplicate_crispr = model->create_crispr(
	    $create_crispr_data->{duplicate_crispr_different_off_target_algorithm} ),
	    'can create dupliate crispr';
	is $duplicate_crispr->id, $crispr->id, 'we have the same crispr';
	ok my $new_off_targets = $duplicate_crispr->off_targets, 'can retrieve new off targets';
	is $new_off_targets->count, 2, '.. we have 2 off target now';
	ok my $easy_off_target = $new_off_targets->find( { algorithm => 'easy' } )
	    , '.. one of which uses the easy algorithm';

	is $duplicate_crispr->off_target_summaries->count, 2, 'We have two off target summaries now';
	ok my $easy_off_target_summary = $duplicate_crispr->off_target_summaries->find( { algorithm => 'easy' } )
	    , 'can find off target summary for easy algorithm';
	is $easy_off_target_summary->algorithm, 'easy', '.. correct algorithm';
	is $easy_off_target_summary->outlier, 0, '.. correct outlier';
    }

    note('Testing retrival of crispr');
    {
	ok my $crispr = model->retrieve_crispr( { id => $crispr->id } ), 'retrieve newly created crispr';
	isa_ok $crispr, 'LIMS2::Model::Schema::Result::Crispr';
	ok my $h = $crispr->as_hash(), 'can call as_hash';
	isa_ok $h, ref {};
	ok $h->{off_targets}, '...has off targets';

	throws_ok {
	    model->retrieve_crispr( { id => 123123123 } );
	}
	'LIMS2::Exception::NotFound', '..can not retreive deleted crispr';
    }

    note('Testing create crispr locus');
    {   
	my $crispr_locus_data = $create_crispr_data->{valid_crispr_locus};
	$crispr_locus_data->{crispr_id} = $crispr->id;

	ok my $crispr_locus = model->create_crispr_locus( $crispr_locus_data )
	    , 'can create new crispr locus';

	is $crispr_locus->assembly_id, 'NCBIM37', '.. assembly is correct';
    }

    note('Testing create crispr off target');
    {
	my $crispr_off_target_data = $create_crispr_data->{valid_crispr_off_target};
	$crispr_off_target_data->{crispr_id} = $crispr->id;

	ok my $crispr_off_target = model->create_crispr_off_target( $crispr_off_target_data )
	    , 'can create new crispr off target';

	is $crispr_off_target->chromosome, 16, '.. crispr off target chromosome is correct';
	is $crispr_off_target->algorithm, 'strict', '.. crispr off target algorithm is correct';

	my $crispr_off_target_data_2 = $create_crispr_data->{crispr_off_target_non_standard_chromosome};
	$crispr_off_target_data_2->{crispr_id} = $crispr->id;

	ok my $crispr_off_target_2 = model->create_crispr_off_target( $crispr_off_target_data_2 )
	    , 'can create new crispr off target';

	is $crispr_off_target_2->chromosome, 'JL154.1', '.. crispr off target chromosome is correct';
    }

    note('Test finding crispr by sequence and locus');
    my $find_crispr_data= test_data( 'find_crispr_by_seq.yaml' );
    {
	my $valid_crispr_data = $find_crispr_data->{valid_find_crispr_by_seq};
	ok my $found_crispr = model->find_crispr_by_seq_and_locus( $valid_crispr_data )
	    , 'can find crispr site by sequence and locus data';
	is $found_crispr->id, $crispr->id, '.. and we have found the same crispr';

	# throw error because missing locus info
	my $invalid_locus_crispr_data = $find_crispr_data->{non_existatant_locus};
	throws_ok {
	    model->find_crispr_by_seq_and_locus( $invalid_locus_crispr_data )
	} qr/Can not find crispr locus information on assembly NCBIM36/
	   , 'throws error because of missing locus information';

	# throw error because multiple identical crisprs
	my $duplicate_crispr_data = $create_crispr_data->{valid_crispr};
	$duplicate_crispr_data->{species_id} = 'Mouse';
	$duplicate_crispr_data->{crispr_loci_type_id} = 'Exonic';
	$duplicate_crispr_data->{off_target_outlier} = 0;
	ok $crispr = model->_create_crispr( $duplicate_crispr_data )
	    , 'can create new duplicate crispr';

	throws_ok{
	    model->find_crispr_by_seq_and_locus( $valid_crispr_data )
	} qr/Found multiple crispr sites/
	    , 'throws correct error when multiple crispr sites with same sequence and locus';
    }

    note('Test deletion of cripr');
    {  

	#add process with crispr
	my $process = model->schema->resultset('Process')->create( { type_id => 'create_crispr' } );
	$process->create_related( process_crispr => { crispr_id => $crispr->id } );

	throws_ok{
	    model->delete_crispr( { id => $crispr->id } )
	} qr/Crispr \d+ has been used in one or more processes/
	    , 'fail to delete crispr that belongs to a create_crispr process';

	ok $process->process_crispr->delete, 'can delete process crispr';
	ok model->delete_crispr( { id => $crispr->id } ), 'can delete newly created crispr';

	throws_ok{
	    model->delete_crispr( { id => 11111111 } )
	} 'LIMS2::Exception::NotFound', 'can not delete non existant crispr';
    }

}
=head1 AUTHOR

Lars G. Erlandsen

=cut

1;

__END__

