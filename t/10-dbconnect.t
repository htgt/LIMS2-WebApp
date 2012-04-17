
use strict;
use warnings FATAL => 'all';

use Test::Most;
use File::Temp;
use Const::Fast;
use YAML::Any;

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

is LIMS2::Model::DBConnect->ConfigFile( $tmp->filename ), $tmp->filename, 'set config file path';

ok my $config = LIMS2::Model::DBConnect->read_config, 'parse config file';

is_deeply $config, \%DB_CONNECT_PARAMS, 'config has expected values';

{
    my %expected = (
        schema_class => 'LIMS2::Model::Schema',
        dsn          => 'dbi:SQLite:dbname=:memory:',
        user         => 'test_one',
        password     => 'eno_tset'
    );
    
    is_deeply LIMS2::Model::DBConnect->params_for( 'lims2_test_one', 'test' ), \%expected,
        'params for lims2_test_one/test';

    local $ENV{LIMS2_DB} = 'lims2_test_one';

    is_deeply LIMS2::Model::DBConnect->params_for( 'LIMS2_DB', 'test' ), \%expected,
        'params for lims2_test_one/test via %ENV';
    
    $expected{AutoCommit} = 1;
    
    is_deeply LIMS2::Model::DBConnect->params_for( 'lims2_test_one', 'test', {AutoCommit => 1} ), \%expected, 
        'params_for lims2_test_one/test with override';

    ok my $s = LIMS2::Model::DBConnect->connect( 'LIMS2_DB', 'test' ), "Connect to lims2_test_one/test";
}

{
    my %expected = (
        schema_class => 'LIMS2::Model::Schema',
        dsn          => 'dbi:SQLite:dbname=:memory:',
        user         => 'test_two_web',
        password     => 'bew_owt_tset'
    );
    
    is_deeply LIMS2::Model::DBConnect->params_for( 'lims2_test_two', 'web' ), \%expected,
        'params for lims2_test_two/web';

    local $ENV{LIMS2_DB} = 'lims2_test_two';

    is_deeply LIMS2::Model::DBConnect->params_for( 'LIMS2_DB', 'web' ), \%expected,
        'params for lims2_test_two/web via %ENV';
    
    ok my $s = LIMS2::Model::DBConnect->connect( 'LIMS2_DB', 'web' ), "Connect to lims2_test_two/web";
}

done_testing;
