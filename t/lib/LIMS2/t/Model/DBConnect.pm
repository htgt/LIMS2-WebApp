package LIMS2::t::Model::DBConnect;
use base qw(Test::Class);
use Test::Most;
use LIMS2::Model::DBConnect;

use File::Temp;
use Const::Fast;
use YAML::Any;


=head1 NAME

LIMS2/t/Model/DBConnect.pm - test class for LIMS2::Model::DBConnect

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
    #const my %DB_CONNECT_PARAMS => (
    const my %DB_CONNECT_PARAMS => (
	lims2_test_one => {
	    schema_class => 'LIMS2::Model::Schema',
	    dsn          => 'dbi:SQLite:dbname=:memory:',
	    roles        => {
		test => { user => 'test_one', password => 'eno_tset' }
	    }
	},
	lims2_test_two => {
	    schema_class => 'LIMS2::Model::Schema',
	    dsn          => 'dbi:SQLite:dbname=:memory:',
	    roles        => {
		test => { user => 'test_two', password => 'owt_tset' },
		web  => { user => 'test_two_web', password => 'bew_owt_tset' }
	    }
	}
    );

    use_ok 'LIMS2::Model::DBConnect';

    my $tmp = File::Temp->new( SUFFIX => '.yaml' );
    $tmp->print( YAML::Any::Dump( \%DB_CONNECT_PARAMS ) );
    $tmp->close;

    is(LIMS2::Model::DBConnect->ConfigFile( $tmp->filename ), $tmp->filename, 'set config file path');

    ok my $config = LIMS2::Model::DBConnect->read_config, 'parse config file';

    is_deeply $config, \%DB_CONNECT_PARAMS, 'config has expected values';

    can_ok 'LIMS2::Model::DBConnect', 'connect';
    {   
	my %expected = (
	    schema_class => 'LIMS2::Model::Schema',
	    dsn          => 'dbi:SQLite:dbname=:memory:',
	    user         => 'test_one',
	    password     => 'eno_tset'
	);

	is_deeply(LIMS2::Model::DBConnect->params_for( 'lims2_test_one', 'test' ), \%expected,
	    'params for lims2_test_one/test');

	local $ENV{LIMS2_DB} = 'lims2_test_one';

	is_deeply(LIMS2::Model::DBConnect->params_for( 'LIMS2_DB', 'test' ), \%expected,
	    'params for lims2_test_one/test via %ENV');

	ok my $s = LIMS2::Model::DBConnect->connect( 'LIMS2_DB', 'test' ), "Connect to lims2_test_one/test";
    }

    {
	my %expected = (
	    schema_class => 'LIMS2::Model::Schema',
	    dsn          => 'dbi:SQLite:dbname=:memory:',
	    user         => 'test_two_web',
	    password     => 'bew_owt_tset'
	);

	is_deeply(LIMS2::Model::DBConnect->params_for( 'lims2_test_two', 'web' ), \%expected,
	    'params for lims2_test_two/web');

	local $ENV{LIMS2_DB} = 'lims2_test_two';

	is_deeply(LIMS2::Model::DBConnect->params_for( 'LIMS2_DB', 'web' ), \%expected,
	    'params for lims2_test_two/web via %ENV');

	ok my $s = LIMS2::Model::DBConnect->connect( 'LIMS2_DB', 'web' ), "Connect to lims2_test_two/web";
    }

}

=head1 AUTHOR

Lars G. Erlandsen

=cut

1;

__END__

