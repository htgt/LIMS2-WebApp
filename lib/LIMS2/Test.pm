package LIMS2::Test;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Test::VERSION = '0.313';
}
## use critic

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        model        => \'_build_model',
        test_data    => \'_build_test_data',
        fixture_data => \'_build_fixture_data',
        'load_static_files', 'load_dynamic_files', 'load_files', 'mech', 'unauthenticated_mech',
        'reload_fixtures', 'wipe_test_data'
    ],
    groups => {
        default => [
            qw( model mech unauthenticated_mech test_data fixture_data load_static_files load_dynamic_files load_files reload_fixtures wipe_test_data )
        ]
    }
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
use LIMS2::Model::Util::RefdataUpload;
use File::Basename;

BEGIN {
    #try not to override the lims2 logger
    unless ( Log::Log4perl->initialized ) {
        Log::Log4perl->easy_init( { level => $OFF } );
    }
}

const my $FIXTURE_RX => qr/^\d\d\-[\w-]+\.sql$/;

# These must match the user/password created in t/fixtures/10-users-roles.t
const my $TEST_USER   => 'test_user@example.org';
const my $TEST_PASSWD => 'ahdooS1e';

sub unauthenticated_mech {
    my $model = shift;
    # Reset the fixture data checksum because webapp
    # may change the database content
    $model ||= LIMS2::Model->new( { user => 'tests' } );

    my $dbh = $model->schema->storage->dbh;
    my $name = db_name($dbh);
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
    my $model = shift;

    my $mech = unauthenticated_mech( $model );

    $mech->get( '/login' );

    $mech->submit_form(
        form_name => 'login_form',
        fields    => { username => $TEST_USER, password => $TEST_PASSWD },
        button    => 'login'
    );

    return $mech;
}

#TODO could remove this, only test that uses this is SummariesWellDescend
#     and there are better ways to reload fixture data
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
        my $fixture_filename = file($filename);
        my $fixture_dirname  = $fixture_filename->dir->stringify;
        $fixture_dirname     = '' if ( $fixture_dirname eq '.' );
        my $fixture_basename = $fixture_filename->basename;
        my $mech             = mech();
        my $final_path       = join( '/', '/test/data', $fixture_dirname );

        #print STDERR "\$final_path = '$final_path'\n";
        $mech->get($final_path);
        my @links = $mech->links();

        #print STDERR Data::Dumper->Dump([\@links], [qw(*links)]);
        for my $link (@links) {
            if ( $fixture_basename eq $link->text ) {
                $mech->get($link);
                if ( $filename =~ m/\.yaml$/ and not $opts{raw} ) {
                    return YAML::Any::Load( $mech->content );
                }
                else {
                    my $ext;
                    ( $ext = $filename ) =~ s/^.*\.//;
                    my ( $data_fh, $data_tmp_filename ) = File::Temp::tempfile(
                        'testdata_XXXX',
                        DIR    => "/var/tmp",
                        SUFFIX => '.' . $ext,
                        UNLINK => 1
                    );
                    $data_fh->print( $mech->content );
                    $data_fh->seek( 0, 0 );
                    return ($data_fh);
                }
            }
        }
    }
}

sub _build_fixture_data {
    my ( $class, $name, $args ) = @_;

    return sub {
        my ( $filename, %opts ) = @_;
        my $fixture_filename = file($filename);
        my $fixture_dirname  = $fixture_filename->dir->stringify;
        $fixture_dirname     = '' if ( $fixture_dirname eq '.' );
        my $fixture_basename = $fixture_filename->basename;
        my $mech             = mech();
        my $final_path       = join( '/', '/test/fixtures', $fixture_dirname );
        $mech->get($final_path);
        my @links = $mech->links();

        for my $link (@links) {
            if ( $fixture_basename eq $link->text ) {
                $mech->get($link);
                if ( $filename =~ m/\.yaml$/ and not $opts{raw} ) {
                    return YAML::Any::Load( $mech->content );
                }
                else {
                    my $ext;
                    ( $ext = $filename ) =~ s/^.*\.//;
                    my ( $data_fh, $data_tmp_filename ) = File::Temp::tempfile(
                        'testdata_XXXX',
                        DIR    => "/var/tmp",
                        SUFFIX => '.' . $ext,
                        UNLINK => 1
                    );
                    $data_fh->print( $mech->content );
                    $data_fh->seek( 0, 0 );
                    return ($data_fh);
                }
            }
        }
    }
}

sub _build_model {
    my ( $class, $name, $args ) = @_;
    my ( $fixture_directory, $new );
    # Fixture data processing
    if ( $args->{classname} ) {
        # Fixture data is derived from the caller's classname, i.e
        #  if the caller package is "A::B::C::D", we look for files in '/data/fixtures/A/B/C/D'
        my $classname = ( $args->{classname} );
        my $classdir;
        ( $classdir = $classname ) =~ s/::/\//g;
        $fixture_directory = '/static/test/fixtures/' . $classdir;
        $new               = 1;
    }
    elsif ( $args->{classdir} ) {
        $fixture_directory = $args->{classdir};
        $new               = 1;
    }
    else {
        $fixture_directory = '/test/fixtures/legacy';
        $new               = 0;
    }

    my $model = LIMS2::Model->new( { user => 'tests'} );

    try {
        $model->schema;
    }
    catch {
        BAIL_OUT( "database connect failed: " . ( $_ || '(unknown failure)' ) );
    };

    unless ( $ENV{SKIP_LOAD_FIXTURES} ) {
        my $mech = mech( $model );
        wipe_test_data( $model, $mech );

        # Reference data (part of every test)
        load_static_files( $model, $mech );
        # Finally load the test data
        if ( $new ) {
            # A complete set of csv files, to be loaded in a specific order
            load_dynamic_files( $model, $mech, $fixture_directory);
        }
        else {
            # Test data delivered in the form of a legacy sql file
            load_files( $model, $mech, $fixture_directory);
        }
    }

    $model->schema->storage->txn_begin;
    return sub {$model};
}

# wipe the test database by running spl file that truncates all
# the non reference data
sub wipe_test_data {
    my ( $model, $mech ) = @_;

    load_files( $model, $mech, '/static/test/fixtures/00-clean-db.sql');

    return;
}

sub load_static_files {
    my ( $model, $mech, $path ) = @_;

    # Default path
    $path ||= '/static/test/fixtures/reference_data';

    # Reference data (part of every test)
    # NB!NB!NB! Need to be loaded in this particular order (database dependencies)!!
    my @reference_tables = (
        qw(
            Backbone
            Cassette
            CassetteFunction
            CellLine
            ColonyCountType
            CrisprPrimerType
            CrisprLociType
            CrisprDamageType
            DesignCommentCategory
            DesignOligoType
            DesignType
            GeneType
            GenotypingPrimerType
            GenotypingResultType
            MutationDesignType
            Nuclease
            PlateType
            PrimerBandType
            ProcessType
            Recombinase
            RecombineeringResultType
            Role
            Species
            Chromosome
            Assembly
            BacLibrary
            SpeciesDefaultAssembly
            Sponsor
            BarcodeState
            CrisprTrackerRna
            )
    );

    for my $table (@reference_tables) {
        load_files( $model, $mech, $path . '/' . $table . '.csv' );
    }

    return;
}

sub load_dynamic_files {
    my ( $model, $mech, $path ) = @_;
    # Default path
    $path ||= '/static/test/fixtures';

    # Dynamic fixture data (not necessarily part of every test)
    # NB!NB!NB! Need to be loaded in this particular order (database dependencies)!!
    my @reference_tables = (
        qw(
            User
            UserRole
            Crispr
            CrisprOffTargets
            CrisprOffTargetSummary
            CrisprLocus
            CrisprPair
            Design
            DesignOligo
            DesignOligoLocus
            GeneDesign
            CrisprDesign
            BacClone
            BacCloneLocus
            Process
            ProcessBackbone
            ProcessCassette
            ProcessCellLine
            ProcessBac
            ProcessRecombinase
            ProcessDesign
            ProcessCrispr
            ProcessNuclease
            ProcessGlobalArmShorteningDesign
            ProcessCrisprTrackerRna
            Plate
            Well
            ProcessInputWell
            ProcessOutputWell
            ProcessDesign
            ProcessRecombinase
            Project
            ProjectSponsor
            Summary
            WellBarcode
            CrisprEsQcRuns
            CrisprEsQcWell
        )
    );

    for my $table ( @reference_tables ) {
        load_files( $model, $mech, $path . '/' . $table . '.csv' );
    }

    return;
}

sub load_files {
    my ( $model, $mech, $path ) = @_;
    my @files;

    $model ||= LIMS2::Model->new( { user => 'tests'} );
    $mech  ||= mech( $model );

    if ( $model->user ne 'tests' ) {
        die( "Model user is not 'tests', will not load files into database: " . $model->user );
    }

    my $schema = $model->schema;
    my $dbh    = $schema->storage->dbh;
    $mech->get($path);
    my @links = $mech->links();

    if (@links) {
        # We were given a directory name (identified by finding an array of links)
        for my $link (@links) {
            push( @files, { url => $link->url, filename => $link->text, reload => 1 } );
        }
    }
    else {
        # We were given a filename
        my ( $base, $dir, $ext ) = fileparse( $path, '\..*' );

        push( @files, { url => $path, filename => $base, reload => 0 } );
    }

    for my $file (@files) {

        my ( $base, $dir, $ext );
        ( $base, $dir, $ext ) = fileparse( $file->{url}, '\..*' );

        if ( $file->{reload} ) {
            $mech->get( $file->{url} );
        }
        # we do not always have test data for all the tables
        next unless $mech->success;

        my $content = $mech->content;
        if ( $ext eq '.sql' ) {
            DEBUG( "Loading sql from " . $file->{url} );

            $dbh->do($content);
        }
        elsif ( $ext eq '.csv' ) {
            DEBUG( "Loading csv from " . $file->{url} );
            my $rs = $schema->resultset($base);

            my ( $data_fh, $data_tmp_filename ) = File::Temp::tempfile(
                'testdata_XXXX',
                DIR    => "/var/tmp",
                SUFFIX => $ext,
                UNLINK => 1
            );
            $data_fh->print($content);
            $data_fh->seek( 0, 0 );
            LIMS2::Model::Util::RefdataUpload::load_csv_file( $data_fh, $rs );
        }
        elsif ( $ext eq '' ) {
            # Empty extension - Take it as a directory link and ignore
        }
        else {
            BAIL_OUT( "Unhandled file extension '." . $ext . "'" );
        }
    }

    return;
}

sub _load_fixtures {
    my ( $dbh, $args ) = @_;

    my $mech = mech();
    my $dir = $args->{dir} || '/static/test/fixtures';
    $mech->get($dir);
    my @links = $mech->links();

    my @fixtures = ( sort { $a->text cmp $b->text } grep { _is_fixture( $_->text ) } @links );

    my $fixture_md5 = _calculate_md5(@fixtures);

    # If we find any new/modified files then reload all fixtures
    if ( _has_new_fixtures( $dbh, $fixture_md5 ) or $args->{force} ) {

        note "loading fixture data";
        my $dbname = db_name($dbh);

        my $admin_role = $dbname . '_admin';

        #$dbh->do( "SET ROLE lims2_test" );
        #Errors: "Bail out!  load fixtures failed: DBI Exception: DBD::Pg::db do failed: ERROR:  relation "fixture_md5" does not exist"
        $dbh->do("SET ROLE lims2");

        foreach my $fixture (@fixtures) {
            DEBUG( "Loading fixtures from " . $fixture->text );
            $mech->get( $fixture->url );
            $dbh->do( $mech->content );
        }
        DEBUG("Updating fixture md5");
        _update_fixture_md5( $dbh, $fixture_md5 );

        # Calling commit warns "commit ineffective with AutoCommit enabled"
        # but it seems to be necessary...
        # turning off warnings briefly to suppress this message
        $dbh->{PrintWarn} = 0;
        $dbh->{Warn}      = 0;
        $dbh->commit;
        $dbh->{PrintWarn} = 1;
        $dbh->{Warn}      = 1;
    }
    else {
        print STDERR "No fixtures to load\n";
    }

    return;
}

sub _is_fixture {
    my $name = shift;

    return $name =~ m/$FIXTURE_RX/;
}

sub _calculate_md5 {
    my @links = @_;

    my $md5 = Digest::MD5->new;

    my $mech = mech();
    foreach my $link (@links) {
        $mech->get( $link->url );
        $md5->add( $mech->content );
    }

    return $md5->hexdigest;
}

sub _has_new_fixtures {
    my ( $dbh, $md5 ) = @_;

    my $existing_md5 = $dbh->selectrow_array("select md5 from fixture_md5");

    if ( $existing_md5 and $existing_md5 eq $md5 ) {
        return 0;
    }

    return 1;
}

sub _update_fixture_md5 {
    my ( $dbh, $md5 ) = @_;

    $dbh->do("delete from fixture_md5");
    my $sth = $dbh->prepare("insert into fixture_md5 values ( ?, now() )")
        or die $dbh->errstr;
    $sth->execute($md5);

    return;
}

1;

__END__

