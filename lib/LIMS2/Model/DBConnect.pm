package LIMS2::Model::DBConnect;

use strict;
use warnings FATAL => 'all';

use base 'Class::Data::Inheritable';

use Carp qw( confess );
use File::stat;
use Config::Any;

BEGIN {
    __PACKAGE__->mk_classdata( 'ConfigFile' => $ENV{LIMS2_DBCONNECT_CONFIG} );
    __PACKAGE__->mk_classdata( 'CachedConfig' );
}

sub config_is_fresh {
    my $class = shift;

    return $class->CachedConfig
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
    my $st       = stat( $filename )
        or confess "stat '$filename': $!";
    
    my $config = Config::Any->load_files( { files => [ $filename ], use_ext => 1, flatten_to_hash => 1 } );
    
    $class->CachedConfig( {
        filename => $filename,
        mtime    => $st->mtime,
        data     => $config->{$filename}
    } );

    return $config->{$filename};
}

sub config {
    my ( $class, $dbname ) = @_;

    my $config = $class->config_is_fresh ? $class->CachedConfig->{data} : $class->read_config;

    return $config->{$dbname} || confess "Database '$dbname' not configured";    
}

sub params_for {
    my ( $class, $dbname, $role, $override_attrs ) = @_;

    $dbname = $ENV{ $dbname } if defined $ENV{ $dbname };

    my %params = %{ $class->config($dbname) };
    my $roles  = delete $params{roles};

    my $role_params = $roles->{$role}
        or confess "Role '$role' for database '$dbname' not configured";

    return { %params, %{$role_params}, %{ $override_attrs || {} } };
}

sub connect {
    my ( $class, $dbname, $role, $override_attrs ) = @_;

    confess 'connect() requires dbname and role'
        unless defined $dbname and defined $role;
    
    my $params = $class->params_for( $dbname, $role, $override_attrs );
    my $schema_class  = $params->{schema_class}
        or confess "No schema_class defined for '$dbname'";
    
    eval "require $schema_class"
        or confess( "Failed to load $schema_class: $@" );

    $schema_class->connect( $params )
}

1;

__END__
