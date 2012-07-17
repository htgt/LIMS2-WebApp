package LIMS2::Test;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Test::VERSION = '0.007';
}
## use critic


use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ model => \'_build_model', test_data => \'_build_test_data', 'mech', 'unauthenticated_mech' ],
    groups => { default => [qw( model mech unauthenticated_mech test_data )] }
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
use Try::Tiny;

const my $FIXTURE_RX => qr/^\d\d\-[\w-]+\.sql$/;

# These must match the user/password created in t/fixtures/10-users-roles.t
const my $TEST_USER   => 'test_user@example.org';
const my $TEST_PASSWD => 'ahdooS1e';

sub unauthenticated_mech {
    return Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'LIMS2::WebApp' );
}

sub mech {
    my $mech = unauthenticated_mech();
    $mech->credentials( $TEST_USER, $TEST_PASSWD );
    return $mech;
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

    for my $fixture ( sort { $a cmp $b } grep { _is_fixture($_) } $fixtures_dir->children ) {
        DEBUG("Loading fixtures from $fixture");
        DBIx::RunSQL->run_sql_file(
            verbose         => 1,
            verbose_handler => \&DEBUG,
            dbh             => $dbh,
            sql             => $fixture
        );
    }

    return;
}

sub _is_fixture {
    my $obj = shift;

    return if $obj->is_dir;

    return $obj->basename =~ m/$FIXTURE_RX/;
}

1;

__END__
