package LIMS2::Model::DBConnect;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::DBConnect::VERSION = '0.528';
}
## use critic


use strict;
use warnings FATAL => 'all';

use base 'Class::Data::Inheritable';

use Carp qw( confess );
use File::stat;
use Config::Any;
use Const::Fast;
use DBIx::Connector;
use Hash::MoreUtils qw( slice_def );
use Log::Log4perl qw( :easy );

BEGIN {
    __PACKAGE__->mk_classdata( 'ConfigFile' => $ENV{LIMS2_DBCONNECT_CONFIG} );
    __PACKAGE__->mk_classdata('CachedConfig');
}

# XXX Incomplete, add further parameters as needed
const my @DBI_ATTRS => qw( AutoCommit PrintError RaiseError );

{
    my %connector_for;

    sub _clear_connectors {
        %connector_for = ();
        return;
    }

    sub _connector_for {
        my ( $class, $dbname, $role, $params ) = @_;

        my $dsn  = delete $params->{dsn};
        my $user = delete $params->{user};
        my $pass = delete $params->{password};
        my %attr = slice_def( $params, @DBI_ATTRS );
        delete $params->{$_} for @DBI_ATTRS;

        unless ( $connector_for{$dbname}{$role} ) {
            $connector_for{$dbname}{$role} = DBIx::Connector->new( $dsn, $user, $pass, \%attr );
        }

        return $connector_for{$dbname}{$role};
    }
}

sub config_is_fresh {
    my $class = shift;

    return
           $class->CachedConfig
        && $class->CachedConfig->{filename}
        && $class->ConfigFile
        && $class->CachedConfig->{filename} eq $class->ConfigFile
        && $class->CachedConfig->{mtime}
        && $class->CachedConfig->{mtime} >= stat( $class->ConfigFile )->mtime;
}

sub read_config {
    my $class = shift;

    my $filename = $class->ConfigFile
        or confess "ConfigFile not specified; is the LIMS2_DBCONNECT_CONFIG environment variable set?";
    my $st = stat($filename)
        or confess "stat '$filename': $!";

    my $config = Config::Any->load_files( { files => [$filename], use_ext => 1, flatten_to_hash => 1 } );

    $class->CachedConfig(
        {   filename => $filename,
            mtime    => $st->mtime,
            data     => $config->{$filename}
        }
    );

    $class->_clear_connectors();

    return $config->{$filename};
}

sub config {
    my ( $class, $dbname ) = @_;

    my $config = $class->config_is_fresh ? $class->CachedConfig->{data} : $class->read_config;

    return $config->{$dbname} || confess "Database '$dbname' not configured";
}

sub params_for {
    my ( $class, $dbname, $role ) = @_;

    $dbname = $ENV{$dbname} if defined $ENV{$dbname};

    my %params = %{ $class->config($dbname) };
    my $roles  = delete $params{roles};

    my $role_params = $roles->{$role}
        or confess "Role '$role' for database '$dbname' not configured";

    return { %params, %{$role_params} };
}

sub connect {
    my ( $class, $dbname, $role ) = @_;

    confess 'connect() requires dbname and role'
        unless defined $dbname and defined $role;

    my $params = $class->params_for( $dbname, $role );
    my $schema_class = delete $params->{schema_class}
        or confess "No schema_class defined for '$dbname'";

    eval "require $schema_class"
        or confess("Failed to load $schema_class: $@");

    my $conn = $class->_connector_for( $dbname, $role, $params );

    DEBUG("LIMS2::Model::DBConnect::connect() - Connecting to database as role '$role' using settings from \$ENV{$dbname} = '$ENV{$dbname}'");
    return $schema_class->connect( sub { $conn->dbh }, $params );
}

1;

__END__
