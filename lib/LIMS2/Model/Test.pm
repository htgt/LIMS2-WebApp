package LIMS2::Model::Test;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports    => [ model => \'_build_model' ],
    groups     => {
        default => [ qw( model ) ]
    }
};

use FindBin;
use LIMS2::Model;
use Log::Log4perl qw( :easy );
use DBIx::RunSQL;
use Const::Fast;
use Path::Class;
use Test::More;
use Try::Tiny;

const my $FIXTURE_RX => qr/^\d\d\-[\w-]+\.sql$/;

sub _build_model {
    my ( $class, $name, $args  ) = @_;

    my $user = $args->{user} || 'tests';
    
    my $model = LIMS2::Model->new( { user => $user } );

    try {
        $model->schema;
    }
    catch {
        BAIL_OUT( "database connect failed: " . ( $_ || '(unknown failure)' ) );
    };

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

    return sub { $model };
}

sub _load_fixtures {
    my ( $dbh, $args ) = @_;

    my $fixtures_dir;
    if ( $args->{fixtures_dir} ) {
        $fixtures_dir = dir( $args->{fixtures_dir} );
    }
    else {
        $fixtures_dir = dir( $FindBin::Bin )->subdir( 'fixtures' );
    }
    
    for my $fixture ( sort { $a cmp $b } grep { _is_fixture( $_ ) }  $fixtures_dir->children ) {
        DEBUG( "Loading fixtures from $fixture" );
        DBIx::RunSQL->run_sql_file(
            verbose         => 1,
            verbose_handler => \&DEBUG,
            dbh             => $dbh,
            sql             => $fixture
        );
    }
}

sub _is_fixture {
    my $obj = shift;

    return if $obj->is_dir;

    return $obj->basename =~ m/$FIXTURE_RX/;
}

1;

__END__
