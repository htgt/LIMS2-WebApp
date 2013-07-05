package LIMS2::t::Model::Plugin::BAC;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::Plugin::BAC;

use LIMS2::Test;

=head1 NAME

LIMS2/t/Model/Plugin/BAC.pm - test class for LIMS2::Model::Plugin::BAC

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

sub all_tests  : Test(11)
{

    my $model = model();

    note "Testing create_bac_clone";

    can_ok $model, 'create_bac_clone';

    my %bac1_data = (
	bac_library => 'black6',
	bac_name    => 'CT7-148D8'
    );

    ok my $bac1 = $model->create_bac_clone( \%bac1_data ),
	'create bac with no locus';

    $bac1_data{id} = $bac1->id;

    is_deeply $bac1->as_hash, \%bac1_data, 'as_hash() returns expected data structure';

    my %bac2_data = (
	bac_library =>  'black6',
	bac_name    =>  'CT7-156D9',
	loci        => [
	    {   
		assembly  => 'NCBIM37',
		chr_end   => 194680061,
		chr_start => 194454015,
		chr_name  => '1'
	    }
	]
    );

    ok my $bac2 = $model->create_bac_clone( \%bac2_data ),
	'create bac with NCBIM37 locus';

    $bac2_data{id} = $bac2->id;

    is_deeply $bac2->as_hash, \%bac2_data, 'as_hash() returns expected data structure';

    note "Testing delete_bac_clone";

    can_ok $model, 'delete_bac_clone';

    ok $model->delete_bac_clone( { bac_library => $bac1->bac_library_id,
				   bac_name    => $bac1->name } ), 'delete bac with no locus';

    ok $model->delete_bac_clone( { bac_library => $bac2->bac_library_id,
				   bac_name    => $bac2->name } ), 'delete bac with NCBIM37 locus';

    {   
	throws_ok{
	    $model->_chr_id_for( 'NCBIM37', '99' );
	} 'LIMS2::Exception::Validation', 'throw error with invalid chromosome name';

    }

    {
	ok my $bac_libraries
	    = $model->list_bac_libraries( { species => 'Mouse' } ), 'can list bac libraries for Mouse';

	is_deeply $bac_libraries, [ '129', 'black6' ], '.. lists expected libraries';
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

1;

__END__

