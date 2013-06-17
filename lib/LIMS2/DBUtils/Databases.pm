package LIMS2::DBUtils::Databases;
use Moose;

use strict;
use warnings;

require LIMS2::Model::DBConnect;
#require File::Temp qw(tempfile tempdir);
require File::Temp;
require Data::Dumper;

sub BUILD {
    my $self = shift;
    $self->connection_params(LIMS2::Model::DBConnect->read_config);
    die unless ($self->source_db);
    die unless ($self->destination_db);
    die unless ($self->source_role);
    die unless ($self->destination_role);
}

#__PACKAGE__->config(
#    schema_class => 'LIMS2::Model::AuthDB',
#    target_connect_info => LIMS2::Model::DBConnect->params_for( 'LIMS2_DB', 'webapp_ro' ),
#    source_connect_info => LIMS2::Model::DBConnect->params_for( 'LIMS2_CLONEFROM_DB', 'webapp_ro' ),
#    postgres_dump => 'pg_dump'
#);

has connection_params => (
    is => 'rw'
);

has 'source_db' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => $ENV{LIMS2_CLONEFROM_DB},
);

has 'destination_db' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => $ENV{LIMS2_DB},
);

has 'source_role' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 'lims2',
);

has 'destination_role' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => 'webapp',
);

has 'overwrite' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 0,
);

# Postgres dump binary
has 'postgres_dump' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '/usr/bin/pg_dump',
);

# Postgres restore binary
has 'postgres_restore' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '/usr/bin/pg_restore',
);

# Postgres 'psql' binary
has 'psql' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '/usr/bin/psql',
);

# resolve connection parameters ({entry, role} => {host, port, database, name, password})
sub check_connection_details
{
    my ($self, $params_ref) = @_;

    # Easy case: Connection details are already present
    return if (exists($params_ref->{connection}));

    # No connection: Go from entry and role to connection details
    $params_ref->{connection} = $self->connection_parameters(database => $params_ref->{database}, role => $params_ref->{role});
    return;
}

# Dig out the connection details from configuration file and dsn connection string
sub connection_parameters {
    my ($self, %params) = @_;

    my $connection_details;

    ($connection_details->{host} = $self->connection_params->{$params{database}}->{dsn}) =~ s/^.*host=([^;]+).*$/$1/g;
    ($connection_details->{port} = $self->connection_params->{$params{database}}->{dsn}) =~ s/^.*port=([^;]+).*$/$1/g;
    ($connection_details->{dbname} = $self->connection_params->{$params{database}}->{dsn}) =~ s/^.*dbname=([^;]+).*$/$1/g;
    $connection_details->{user} = $self->connection_params->{$params{database}}->{roles}->{$params{role}}->{user};
    $connection_details->{password} = $self->connection_params->{$params{database}}->{roles}->{$params{role}}->{password};
    print STDERR Data::Dumper->Dump([\$params{database}, \$connection_details],[qw(database connection_details)]);
    return ($connection_details);
}

# Check if a database exists on a postgres server
sub database_exists
{
    my ($self, %params) = @_;

    # Do we have a source or target database
    $ENV{PGPASSWORD} = $params{connection}->{password};
    my $list_source_database_query =
	$self->psql .
	" -l" .
	" -A" .
	" -h " . $params{connection}->{host} .
	" -p " . $params{connection}->{port} .
	" --username=" . $params{connection}->{user} .
	" --no-password" .
	" | egrep '^" . $params{connection}->{dbname} . "\\b'" .
	" | wc -l"
    ;
	#((exists($params{no_role}) && $params{no_role}) ?  '' : " --role=" . $params{role}) .
    my $has_db = `$list_source_database_query`;
    chomp($has_db);
    print STDERR Data::Dumper->Dump([\$list_source_database_query, \$has_db],[qw(list_source_database_query has_db)]);

    return($has_db);
}

# Dump a database definition to a (temporary) file
sub dump_database_definition
{
    my ($self, %params) = @_;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    # File to use for schema dump
    #my $dir = File::Temp::tempdir( CLEANUP => 1 );
    #my ($fh_schema, $filename_schema) = File::Temp::tempfile( 'schema_XXXXXXXX', DIR => $dir, SUFFIX => '.dump' );
    my ($fh_schema, $filename_schema) = File::Temp::tempfile( 'schema_XXXXXXXX', DIR => '/tmp', SUFFIX => '.dump' );
    print STDERR Data::Dumper->Dump([\$filename_schema],[qw(filename_schema)]);

    # Dump schema using pg_dump
    $ENV{PGPASSWORD} = $params{connection}->{password};
    my $dump_query =
	$self->postgres_dump .
	($params{with_data} ? '' : " --schema-only") .
	" --no-privileges" .
	" --no-owner" .
	" --no-acl" .
	" --create" .
	# tar format, suitable for pg_restore
	" -Ft" .
	" -h " . $params{connection}->{host} .
	" -p " . $params{connection}->{port} .
	((exists($params{no_role}) && $params{no_role}) ?  '' : " --role=" . $params{role}) .
	" --file=" . $filename_schema .
	" --username=" . $params{connection}->{user} .
	" --no-password " .
	$params{connection}->{dbname}
    ;
    print STDERR Data::Dumper->Dump([\$dump_query],[qw(dump_query)]);

    `$dump_query`;
    return($filename_schema);
}

# Restore a database definition from a (temporary) file
sub restore_database
{
    my ($self, %params) = @_;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    # Restoring using pg_restore
    $ENV{PGPASSWORD} = $params{connection}->{password};
    my $restore_query =
	$self->postgres_restore .
	" --exit-on-error" .
	" -h " . $params{connection}->{host} .
	" -p " . $params{connection}->{port} .
	((exists($params{no_role}) && $params{no_role}) ?  '' : " --role=" . $params{role}) .
	" --username=" . $params{connection}->{user} .
	" --no-password " .
	" -d " . $params{connection}->{dbname} .
	" " . $params{schema}
    ;

    print STDERR Data::Dumper->Dump([\$restore_query],[qw(restore_query)]);

    `$restore_query`;
}

# Load fixture data from a file
sub load_fixture
{
    my ($self, %params) = @_;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    # Load using psql
    $ENV{PGPASSWORD} = $params{connection}->{password};
    my $load_query =
	$self->psql .
	" -h " . $params{connection}->{host} .
	" -p " . $params{connection}->{port} .
	" --username=" . $params{connection}->{user} .
	" --no-password " .
	" -f " . $params{file} .
	" " . $params{connection}->{dbname}
    ;

    print STDERR Data::Dumper->Dump([\$load_query],[qw(load_query)]);

    `$load_query`;
}

# Run a query in the database
sub run_query
{
    my ($self, %params) = @_;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    die "No connection details" unless (exists($params{connection}));

    # Run command using psql
    $ENV{PGPASSWORD} = $params{connection}->{password};
    my $run_query =
	$self->psql .
	" -h " . $params{connection}->{host} .
	" -p " . $params{connection}->{port} .
	" --username=" . $params{connection}->{user} .
	" --no-password " .
	" -c " . "\"" . $params{query} . "\"" .
	" " . $params{connection}->{dbname}
    ;

    print STDERR Data::Dumper->Dump([\$run_query],[qw(run_query)]);

    my $ret = `$run_query`;
    return($ret);
}

# Create a new database based on the content in a separate database.
#  1. The schema is copied without any role or ownership information
#  2. The data is copied over
#  3. A new role structure is created
sub clone_database
{
    my ($self, %params) = @_;
    my ($ret);

    # Default arguments where none are provided
    $params{source_db} ||= $self->source_db;
    $params{source_role} ||= $self->source_role;
    $params{destination_db} ||= $self->destination_db;
    $params{destination_role} ||= $self->destination_role;
    $params{overwrite} ||= $self->overwrite;

    my $source_connection_details = $self->connection_parameters(database => $params{source_db}, role => $params{source_role});
    my $destination_connection_details = $self->connection_parameters(database => $params{destination_db}, role => $params{destination_role});

    die "Cannot overwrite a live database" if ($destination_connection_details->{dbname} =~ m/live/i);

    # Do we have a source database
    my $has_source_db = $self->database_exists(connection => $source_connection_details);

    # Do we have a destination database
    #my $has_destination_db;
    my $has_destination_db = $self->database_exists(connection => $destination_connection_details);

    #die "Not allowed to overwrite the destination database" if (($has_destination_db) && (!$params{overwrite});

#    my $source_dbh = LIMS2::Model::DBConnect->connect($self->source_db, $self->source_role)
#	or die "Failed to connect to database '$self->source_db' as user '$self->source_role'";
#    print STDERR Data::Dumper->Dump([\$source_dbh],[qw(source_dbh)]);

#    my $destination_dbh = LIMS2::Model::DBConnect->connect($self->destination_db, $self->source_role)
#	or die "Failed to connect to database '$self->destination_db' as user '$self->destination_role'";
#    #print STDERR Data::Dumper->Dump([\$destination_dbh],[qw(destination_dbh)]);

    # Dump database definition to disk
    my $source_definition_dumpfile = $self->dump_database_definition(connection => $source_connection_details, role => $params{source_role}, no_role => $params{no_source_role}, with_data => $params{with_data} );

    # Drop database (where needed)
    if ($has_destination_db)
    {
	$ret = $self->run_query(connection => { %{$destination_connection_details}, dbname => 'template1'}, role => $params{destination_role}, query => "drop database if exists $destination_connection_details->{dbname}");
    }

    # Create database
    $ret = $self->run_query(connection => { %{$destination_connection_details}, dbname => 'template1'}, role => $params{destination_role}, query => "create database $destination_connection_details->{dbname}");

    # Restore to target
    $ret = $self->restore_database(connection => $destination_connection_details, schema => $source_definition_dumpfile, role => $params{destination_role}, no_role => $params{no_destination_role}, overwrite => $params{overwrite});
}


=head1 NAME

LIMS2::DBUtils::Databases - LIMS2 database maintenance utilities

=head1 SYNOPSIS

See L<LIMS2>

=head1 DESCRIPTION

L<LIMS2::DBUtils::Databases> Utilities to handle changes on database level: Clone databases, load fixture data

=head1 AUTHOR

Lars G. Erlandsen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__


