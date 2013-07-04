package LIMS2::Test;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Test::VERSION = '0.086';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ model => \'_build_model', test_data => \'_build_test_data', 'mech', 'unauthenticated_mech', 'reload_fixtures' ],
    groups => { default => [qw( model mech unauthenticated_mech test_data reload_fixtures)] }
};

use FindBin;
use LIMS2::Model;
use Log::Log4perl qw( :easy );
use DBIx::RunSQL;
use Const::Fast;
use FindBin;
use YAML::Any;
use Path::Class;
use Test::More;
use Test::WWW::Mechanize::Catalyst;
use File::Temp;
use Try::Tiny;
use Digest::MD5;
use LIMS2::Model::Util::PgUserRole qw( db_name );

const my $FIXTURE_RX => qr/^\d\d\-[\w-]+\.sql$/;

# These must match the user/password created in t/fixtures/10-users-roles.t
const my $TEST_USER   => 'test_user@example.org';
const my $TEST_PASSWD => 'ahdooS1e';

sub unauthenticated_mech {

	# Reset the fixture data checksum because webapp
	# may change the database content
	my $model = LIMS2::Model->new( { user => 'tests' } );
	my $dbh = $model->schema->storage->dbh;
	my $name = db_name($dbh);
	$dbh->do("delete from fixture_md5") or die $dbh->errstr;

	# This warns "commit ineffective with AutoCommit enabled"
	# but it seems to be necessary...
    $dbh->commit;

    return Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'LIMS2::WebApp' );
}

sub mech {
    my $mech = unauthenticated_mech();

    $mech->get( '/login' );

    $mech->submit_form(
        form_name => 'login_form',
        fields    => { username => $TEST_USER, password => $TEST_PASSWD },
        button    => 'login'
    );

    return $mech;
}

sub reload_fixtures {

    my $model = LIMS2::Model->new( { user => 'tests' } );
    my $args = { force => 1 };

    try {
        $model->schema->storage->dbh_do(
            sub {
                my ( $storage, $dbh ) = @_;
                _load_fixtures( $dbh, $args );
            }
        );
    }
    catch {
        BAIL_OUT( "load fixtures failed: " . ( $_ || '(unknown failure)' ) );
    };

    return 1;
}

sub _build_test_data {
    my ( $class, $name, $args ) = @_;

    my $data_dir;
    if ( $args->{dir} ) {
        $data_dir = dir( $args->{dir} );
    }
    else {
        $data_dir = dir($FindBin::Bin)->subdir('data');
    }

    return sub {
        my ( $filename, %opts ) = @_;

        my $file = $data_dir->file($filename);

        if ( $filename =~ m/\.yaml$/ and not $opts{raw} ) {
            return YAML::Any::LoadFile($file);
        }

        return $file;
    };
}

sub _build_model {
    my ( $class, $name, $args ) = @_;

    my $user = $args->{user} || 'tests';

    my $model = LIMS2::Model->new( { user => $user } );

    try {
        $model->schema;
    }
    catch {
        BAIL_OUT( "database connect failed: " . ( $_ || '(unknown failure)' ) );
    };

    unless ( $ENV{SKIP_LOAD_FIXTURES} ) {
        try {
            $model->schema->storage->dbh_do(
                sub {
                    my ( $storage, $dbh ) = @_;
                    _load_fixtures( $dbh, $args );
                }
            );
        }
        catch {
            BAIL_OUT( "load fixtures failed: " . ( $_ || '(unknown failure)' ) );
        };
    }

    $model->schema->storage->txn_begin;
    return sub {$model};
}

sub _load_fixtures {
    my ( $dbh, $args ) = @_;

    my $fixtures_dir;
    if ( $args->{fixtures_dir} ) {
        $fixtures_dir = dir( $args->{fixtures_dir} );
    }
    else {
        $fixtures_dir = dir($FindBin::Bin)->subdir('fixtures');
    }

    my @fixtures = ( sort { $a cmp $b } grep { _is_fixture($_) } $fixtures_dir->children );

    my $fixture_md5 = _calculate_md5(@fixtures);

    # If we find any new/modified files then reload all fixtures
    if ( _has_new_fixtures($dbh, $fixture_md5) or $args->{force} ){

    	print STDERR "loading fixture data";

        my $dbname = db_name( $dbh );

        my $admin_role = $dbname . '_admin';

        $dbh->do( "SET ROLE $admin_role" );

    	foreach my $fixture (@fixtures){
            DEBUG("Loading fixtures from $fixture");
            DBIx::RunSQL->run_sql_file(
                verbose         => 1,
                verbose_handler => \&DEBUG,
                dbh             => $dbh,
                sql             => $fixture
            );
    	}
    	_update_fixture_md5($dbh, $fixture_md5);

	    # This warns "commit ineffective with AutoCommit enabled"
	    # but it seems to be necessary...
    	$dbh->commit;

    	$dbh->do( "RESET ROLE" );
    }

    return;
}

sub _is_fixture {
    my $obj = shift;

    return if $obj->is_dir;

    return $obj->basename =~ m/$FIXTURE_RX/;
}

sub _calculate_md5{
    my @files = @_;

    my $md5 = Digest::MD5->new;

    foreach my $file (@files){
    	open (my $fh, "<", $file) or die "Could not open $file for MD5 digest - $!";
        $md5->addfile($fh);
        close $fh;
    }

    return $md5->hexdigest;
}

sub _has_new_fixtures {
    my ($dbh, $md5) = @_;

    my $existing_md5 = $dbh->selectrow_array("select md5 from fixture_md5");

    if($existing_md5 and $existing_md5 eq $md5){
    	return 0;
    }

    return 1;
}

sub _update_fixture_md5{
	my ($dbh, $md5) = @_;

	$dbh->do("delete from fixture_md5");
	my $sth = $dbh->prepare("insert into fixture_md5 values ( ?, now() )")
	    or die $dbh->errstr;
	$sth->execute($md5);

	return;
}

1;

__END__
