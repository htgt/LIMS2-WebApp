package LIMS2::Test;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Test::VERSION = '0.102';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ model => \'_build_model', test_data => \'_build_test_data', 'mech', 'unauthenticated_mech', 'reload_fixtures' ],
    groups => { default => [qw( model mech unauthenticated_mech test_data reload_fixtures)] }
};

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

    my $model = LIMS2::Model->new( { user => 'tests' } );

	my $dbh = $model->schema->storage->dbh;
	# Reset the fixture data checksum because webapp
	# may change the database content
	$dbh->do("delete from fixture_md5") or die $dbh->errstr;

    # Calling commit warns "commit ineffective with AutoCommit enabled"
    # but it seems to be necessary...
    # turning of warnings briefly to suppress this message
    $dbh->{PrintWarn} = 0;
    $dbh->{Warn} = 0;
    $dbh->commit;
    $dbh->{PrintWarn} = 1;
    $dbh->{Warn} = 1;

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

    return sub {
	my ( $filename, %opts ) = @_;
	my $mech = mech();
	$mech->get( '/test/data' );
	my @links = $mech->links();
	for my $link (@links)
	{
	    if ($filename eq $link->text)
	    {
		$mech->get( $link );
		if ($filename =~ m/\.yaml$/ and not $opts{raw} ) {
		    return YAML::Any::Load($mech->content);
		} else {
		    my $ext;
		    ($ext = $filename) =~ s/^.*\.//;
		    my ($data_fh, $data_tmp_filename) = File::Temp::tempfile( 'testdata_XXXX', DIR => "/var/tmp", SUFFIX => '.' . $ext, UNLINK => 0 );
		    $data_fh->print($mech->content);
		    $data_fh->seek( 0, 0 );
		    return($data_fh);
		}
	    }
	}
    }
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

    my $mech = mech();
    $mech->get( '/test/fixtures' );
    my @links = $mech->links();

    my @fixtures = ( sort { $a->text cmp $b->text } grep { _is_fixture($_->text) } @links );

    my $fixture_md5 = _calculate_md5(@fixtures);

    # If we find any new/modified files then reload all fixtures
    if ( _has_new_fixtures($dbh, $fixture_md5) or $args->{force} ){

        note "loading fixture data";

        # This is not needed, but its nice as a sanity check
        $dbh->do( "SET ROLE lims2_test" );

    	foreach my $fixture (@fixtures){
            DEBUG("Loading fixtures from " . $fixture->text);
            $mech->get( $fixture->url );
            $dbh->do( $mech->content );
    	}
        note "Updating fixture md5";
    	_update_fixture_md5($dbh, $fixture_md5);

	    # Calling commit warns "commit ineffective with AutoCommit enabled"
	    # but it seems to be necessary...
        # turning of warnings briefly to suppress this message
        $dbh->{PrintWarn} = 0;
        $dbh->{Warn} = 0;
    	$dbh->commit;
        $dbh->{PrintWarn} = 1;
        $dbh->{Warn} = 1;
    }
    else
    {
	print STDERR "No fixtures to load\n";
    }

    return;
}

sub _is_fixture {
    my $name = shift;

    return $name =~ m/$FIXTURE_RX/;
}

sub _calculate_md5{
    my @links = @_;

    my $md5 = Digest::MD5->new;

    my $mech = mech();
    foreach my $link (@links){
        $mech->get( $link->url );
        $md5->add($mech->content);
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
