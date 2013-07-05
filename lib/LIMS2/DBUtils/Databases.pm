package LIMS2::DBUtils::Databases;
use Moose;

use strict;
use warnings;

require LIMS2::Model::DBConnect;
#require File::Temp qw(tempfile tempdir);
require File::Temp;
require Data::Dumper;

use Log::Log4perl qw( :easy );

Log::Log4perl->easy_init($DEBUG);

=head1 NAME

LIMS2::DBUtils::Databases - LIMS2 database maintenance utilities

=head1 SYNOPSIS

See L<LIMS2>

=head1 DESCRIPTION

L<LIMS2::DBUtils::Databases> Utilities to handle changes on database level: Clone databases, load fixture data

=head1 AUTHOR

Lars G. Erlandsen

=cut

has connection_params => (
    is => 'rw'
);

has 'source_defn' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => $ENV{LIMS2_CLONEFROM_DB},
);

has 'destination_defn' => (
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

=head1 METHODS

=cut

=head2 BUILD

=cut

sub BUILD {
    my $self = shift;
    $self->connection_params(LIMS2::Model::DBConnect->read_config);
    die unless ($self->source_defn);
    die unless ($self->destination_defn);
    die unless ($self->source_role);
    die unless ($self->destination_role);
}

=head2 check_connection_details

resolve connection parameters ({entry, role} => {host, port, database, name, password})

=cut

sub check_connection_details
{
    my ($self, $params_ref) = @_;

    # Easy case: Connection details are already present
    return if (exists($params_ref->{connection}));

    # No connection: Go from entry and role to connection details
    $params_ref->{connection} = $self->connection_parameters(definition => $params_ref->{definition}, role => $params_ref->{role});
    return;
}

=head2 connection_parameters

Dig out the connection details from configuration file and dsn connection string

=cut

sub connection_parameters {
    my ($self, %params) = @_;

    my $connection_details;

    ($connection_details->{host} = $self->connection_params->{$params{definition}}->{dsn}) =~ s/^.*host=([^;]+).*$/$1/g;
    ($connection_details->{port} = $self->connection_params->{$params{definition}}->{dsn}) =~ s/^.*port=([^;]+).*$/$1/g;
    ($connection_details->{dbname} = $self->connection_params->{$params{definition}}->{dsn}) =~ s/^.*dbname=([^;]+).*$/$1/g;
    $connection_details->{user} = $self->connection_params->{$params{definition}}->{roles}->{$params{role}}->{user};
    $connection_details->{password} = $self->connection_params->{$params{definition}}->{roles}->{$params{role}}->{password};
    DEBUG(Data::Dumper->Dump([\$params{definition}, \$connection_details],[qw(definition connection_details)]));
    return ($connection_details);
}

=head2 database_exists

Check if a database exists on a postgres server

=cut

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
    DEBUG(Data::Dumper->Dump([\$list_source_database_query, \$has_db],[qw(list_source_database_query has_db)]));

    return($has_db);
}

=head2 dump_database_definition

Dump a database schema definition to a (temporary) file

=cut

sub dump_database_definition
{
    my ($self, %params) = @_;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    # File to use for schema dump
    my ($fh_schema, $filename_schema) = File::Temp::tempfile( 'schema_XXXXXXXX', DIR => "/var/tmp", SUFFIX => '.dump', UNLINK => 1 );
    #my ($fh_schema, $filename_schema) = File::Temp::tempfile( 'schema_XXXXXXXX', DIR => "/var/tmp", SUFFIX => '.dump', UNLINK => 0 );
    chmod 0664, $filename_schema;
    DEBUG(Data::Dumper->Dump([\$filename_schema],[qw(filename_schema)]));

    # Dump schema using pg_dump
    $ENV{PGPASSWORD} = $params{connection}->{password};
    my $dump_query =
	$self->postgres_dump .
	($params{with_data} ? '' : " --schema-only") .
	" --no-privileges" .
	" --no-owner" .
	" --no-acl" .
	($params{with_data} ? " --data-only" : " --create") .
	# tar format, suitable for pg_restore
	#($params{with_data} ? '' : " -Ft") .
	# schema, if provided
	($params{schema} ? " --schema=" . $params{schema} : '') .
	" -h " . $params{connection}->{host} .
	" -p " . $params{connection}->{port} .
	((exists($params{no_role}) && $params{no_role}) ?  '' : " --role=" . $params{role}) .
	" --file=" . $filename_schema .
	" --username=" . $params{connection}->{user} .
	" --no-password " .
	$params{connection}->{dbname} .
	' 2>&1'
    ;
    DEBUG(Data::Dumper->Dump([\$dump_query],[qw(dump_query)]));

    my $ret = `$dump_query`;
    print STDERR $ret if ($ret =~ m/ERROR/);
    return(($ret =~ m/ERROR/) ? '' : $filename_schema);
}

=head2 restore_database

Restore a database definition from a (temporary) file

=cut

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
	" --no-owner" .
	" -h " . $params{connection}->{host} .
	" -p " . $params{connection}->{port} .
	((exists($params{no_role}) && $params{no_role}) ?  '' : " --role=" . $params{role}) .
	" --username=" . $params{connection}->{user} .
	" --no-password " .
	" -d " . $params{connection}->{dbname} .
	" " . $params{schema} .
	' 2>&1'
    ;

    DEBUG(Data::Dumper->Dump([\$restore_query],[qw(restore_query)]));

    my $ret = `$restore_query`;
    print STDERR $ret if ($ret =~ m/ERROR/);
    return(($ret =~ m/ERROR/) ? 0 : 1);
}

=head2 load_fixture

Load fixture data from a file

=cut

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
	" " . $params{connection}->{dbname} .
	' 2>&1'
    ;

    DEBUG(Data::Dumper->Dump([\$load_query],[qw(load_query)]));

    my $ret = `$load_query`;
    print STDERR $ret if ($ret =~ m/ERROR/);
    return(($ret =~ m/ERROR/) ? 0 : 1);
}

=head2 run_query

Run a query in the database

=cut

sub run_query
{
    my ($self, %params) = @_;

    # Safeguard query from quotes
    my $query = $params{query};
    $query =~ s/"/\\"/g;

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
	" -c " . "\"" . $query . "\"" .
	" " . $params{connection}->{dbname} .
	' 2>&1'
    ;

    DEBUG(Data::Dumper->Dump([\$run_query],[qw(run_query)]));

    my $ret = `$run_query`;
    print STDERR $ret if ($ret =~ m/ERROR/);
    return(($ret =~ m/ERROR/) ? 0 : 1);
}

=head2 clone_database

Create a new database based on the content in a separate database.
 1. The schema is copied out without any role or ownership information
 2. The schema is 'doctored' to change database name and procedural language creation
     (using pg_dump and pg_restore allows database renaming, but cannot control plpgsql language creation)
 3. The schema is loaded into the target server
 4. The data is copied over
 5. A new role structure is created

=cut

sub clone_database
{
    my ($self, %params) = @_;
    my ($ret);
    my ($source_definition_dumpfile, $source_data_dumpfile);
    my ($role_structure);

    # Default arguments where none are provided
    $params{source_defn} ||= $self->source_defn;
    $params{source_role} ||= $self->source_role;
    $params{destination_defn} ||= $self->destination_defn;
    $params{destination_role} ||= $self->destination_role;
    $params{overwrite} ||= $self->overwrite;

    my $source_connection_details = $self->connection_parameters(definition => $params{source_defn}, role => $params{source_role});
    my $destination_connection_details = $self->connection_parameters(definition => $params{destination_defn}, role => $params{destination_role});
    $params{destination_db} ||= $destination_connection_details->{dbname};

    die "Cannot overwrite a live database" if ($destination_connection_details->{dbname} =~ m/live/i);

    # Do we have a source database
    my $has_source_db = $self->database_exists(connection => $source_connection_details);

    # Do we have a destination database
    my $has_destination_db = $self->database_exists(connection => $destination_connection_details);

    #die "Not allowed to overwrite the destination database" if (($has_destination_db) && (!$params{overwrite});

    # Dump database definition to disk
    $source_definition_dumpfile = $self->dump_database_definition(connection => $source_connection_details, role => $params{source_role}, no_role => $params{no_source_role}, with_data => 0 );
    die "Failed to create a database definition dump" unless ((-e $source_definition_dumpfile) && (-s $source_definition_dumpfile));
    # Amend the definition
    {
	local $/;
	open (FH, "+<", $source_definition_dumpfile) or die "Opening: $!";
	my $content = <FH>;
	$content =~ s/Name: $source_connection_details->{dbname};/Name: $params{destination_db};/g;
	$content =~ s/CREATE DATABASE $source_connection_details->{dbname}/CREATE DATABASE $params{destination_db}/g;
	$content =~ s/\\connect $source_connection_details->{dbname}/\\connect $params{destination_db}/g;
	$content =~ s/CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;/-- CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;/g;
	$content =~ s/CREATE EXTENSION IF NOT EXISTS plpgsql/-- CREATE EXTENSION IF NOT EXISTS plpgsql/g;
	$content =~ s/COMMENT ON EXTENSION plpgsql/-- COMMENT ON EXTENSION plpgsql/g;
	seek(FH, 0, 0) or die "Seeking: $!";
	print FH $content or die "Printing: $!";
	truncate(FH, tell(FH)) or die "Truncating: $!";
	close(FH) or die "Closing: $!";
    }


    # Copy data (if desired)
    if ($params{with_data})
    {
	# Copy data, but from 'public' schema only
	$source_data_dumpfile = $self->dump_database_definition(connection => $source_connection_details, role => $params{source_role}, no_role => $params{no_source_role}, with_data => 1, schema => 'public' );
	die "Failed to create a database content dump" unless ((-e $source_data_dumpfile) && (-s $source_data_dumpfile));
    }

    # Drop database (where needed)
    if ($has_destination_db)
    {
	$ret = $self->run_query(connection => { %{$destination_connection_details}, dbname => 'template1'}, role => $params{destination_role}, query => "drop database if exists $params{destination_db}");
	die "Failed to run database query" unless ($ret);

    }

    # Create database (no longer needed)
    #$ret = $self->run_query(connection => { %{$destination_connection_details}, dbname => 'template1'}, role => $params{destination_role}, query => "create database $params{destination_db}");
    #die "Failed to run database query" unless ($ret);

    # Restore to target
    $ret = $self->load_fixture(connection => { %{$destination_connection_details}, dbname => 'template1'}, role => $params{destination_role}, file => $source_definition_dumpfile);
    die "Failed to restore the schema" unless ($ret);
    if ($params{with_data})
    {
	# Copy data
	$ret = $self->load_fixture(connection => { %{$destination_connection_details}, dbname => $params{destination_db}}, role => $params{destination_role}, file => $source_data_dumpfile);
#	$ret = $self->restore_database(connection => { %{$destination_connection_details}, dbname => $params{destination_db}}, schema => $source_data_dumpfile, role => $params{destination_role}, no_role => $params{no_destination_role}, overwrite => $params{overwrite});
	die "Failed to restore the data" unless ($ret);

	# Now truncate all audit tables after they have filled up with 'gunk'
	my $truncate_audit_command = <<'HERE_TARGET';
	    set search_path = audit, pg_catalog;
	    DO
	    \$func\$
	    BEGIN
	       EXECUTE (
		  SELECT 'TRUNCATE TABLE '
			 || string_agg('audit.' || quote_ident(t.tablename), ', ')
			 || ' CASCADE'
		  FROM   pg_tables t
		  WHERE  t.schemaname = 'audit'
	       );
	    END
	    \$func\$;
HERE_TARGET

	$ret = $self->run_query(connection => { %{$destination_connection_details}, dbname => $params{destination_db}}, query => $truncate_audit_command);
	die "Failed to truncate audit tables" unless ($ret);
    }

    # Restore a minimum set of test roles
    if ($params{create_test_role}) {
	$role_structure = <<'HERE_TARGET';
	    drop role if exists "lims2_test";
	    create role "lims2_test" with encrypted password 'test_passwd' login noinherit;

	    drop role if exists "test_user@example.org";
	    create role "test_user@example.org" with nologin inherit;
	    grant lims2 to "test_user@example.org";

	    -- test_db_add_fixture_md5.sql:
	    CREATE TABLE fixture_md5 (
	       md5         TEXT NOT NULL,
	       created_at  TIMESTAMP NOT NULL
	    );
	    GRANT SELECT ON fixture_md5 TO "lims2_test";
	    GRANT SELECT, INSERT, UPDATE, DELETE ON fixture_md5 TO "lims2_test";
	    grant all on fixture_md5 to "lims2";
HERE_TARGET

	$ret = $self->run_query(connection => { %{$destination_connection_details}, dbname => $params{destination_db}}, query => $role_structure);
	die "Failed to create test roles" unless ($ret);
    }

    return 1;

}


=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__


