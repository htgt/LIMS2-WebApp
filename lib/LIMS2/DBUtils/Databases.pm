package LIMS2::DBUtils::Databases;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::DBUtils::Databases::VERSION = '0.493';
}
## use critic

use Moose;

#use strict;
#use warnings;

require LIMS2::Model::DBConnect;
#require File::Temp qw(tempfile tempdir);
require File::Temp;
require Data::Dumper;
use IPC::Run qw( run timeout );

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
    default => $ENV{'PG_DUMP_EXE'} // '/usr/bin/pg_dump',
);

# Postgres restore binary
has 'postgres_restore' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => $ENV{'PG_RESTORE_EXE'} // '/usr/bin/pg_restore',
);

# Postgres 'psql' binary
has 'psql' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => $ENV{'PSQL_EXE'} // '/usr/bin/psql',
);

=head1 METHODS

=cut

=head2 BUILD

=cut

## no critic(RequireFinalReturn)
sub BUILD {
    my $self = shift;
    $self->connection_params(LIMS2::Model::DBConnect->read_config);
    die unless ($self->source_defn);
    die unless ($self->destination_defn);
    die unless ($self->source_role);
    die unless ($self->destination_role);
}
## use critic

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
    my ($input, $output, $error);

    # Do we have a source or target database
    local $ENV{PGPASSWORD} = $params{connection}->{password};
    my @list_source_database_query = (
	$self->psql,
	'-l',
	'-A',
	'-h', $params{connection}->{host},
	'-p', $params{connection}->{port},
	'-U', $params{connection}->{user},
	'--no-password',
    );
    my $query = join(' ', @list_source_database_query );

    DEBUG('Running query: ' . $query);
    run \@list_source_database_query, \$input, \$output, \$error, timeout(10) or die "psql: $?";
    #DEBUG(Data::Dumper->Dump([\$output],[qw(output)]));
    DEBUG("Query '$query' produced error output '$error'") if ($error);

    my $matched = 0;
    if ($output =~ m/^$params{connection}->{dbname}\b/m) {
	$matched = 1;
    }
    DEBUG("Matched is : $matched");

    return($matched);
}

=head2 dump_database_definition

Dump a database schema definition to a (temporary) file

=cut

sub dump_database_definition
{
    my ($self, %params) = @_;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    my $unlink = $params{keep_temporary_files} ? 0 : 1;
    # File to use for schema dump
    my ($fh_schema, $filename_schema) = File::Temp::tempfile( 'schema_XXXXXXXX', DIR => "/var/tmp", SUFFIX => '.dump', UNLINK => $unlink );
    chmod 0664, $filename_schema;
    DEBUG(Data::Dumper->Dump([\$filename_schema],[qw(filename_schema)]));

    # Dump schema using pg_dump
    local $ENV{PGPASSWORD} = $params{connection}->{password};
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

    my $ret = system($dump_query);
    print STDERR $ret if ($ret =~ m/ERROR/);
    return $ret =~ m/ERROR/ ? '' : $filename_schema;
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
    local $ENV{PGPASSWORD} = $params{connection}->{password};
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

    my $ret = system($restore_query);
    print STDERR $ret if ($ret =~ m/ERROR/);
    return $ret =~ m/ERROR/ ? 0 : 1;
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
    local $ENV{PGPASSWORD} = $params{connection}->{password};
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

    my $ret = system($load_query);
    print STDERR $ret if ($ret =~ m/ERROR/);
    return $ret =~ m/ERROR/ ? 0 : 1;
}

=head2 run_query

Run a query in the database

=cut

## no critic(RequireFinalReturn)
sub run_query
{
    my ($self, %params) = @_;
    my ($input, $output, $error);

    $input = $params{query};

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    die "No connection details" unless (exists($params{connection}));

    # Run command using psql
    local $ENV{PGPASSWORD} = $params{connection}->{password};
    my @run_query = (
	$self->psql,
	'-h', $params{connection}->{host},
	'-p', $params{connection}->{port},
	'-U', $params{connection}->{user},
	'--no-password',
	$params{connection}->{dbname}
    );
    my $query = join(' ', @run_query);

    DEBUG(Data::Dumper->Dump([\$input],[qw(query)]));

    run \@run_query, \$input, \$output, \$error, timeout(10) or die "psql: $?";
    DEBUG("Query '$input' produced error output '$error'") if ($error);

    return $error =~ m/ERROR/ ? 0 : 1;
}
## use critic


=head2 create_testroles

Create test roles in the database

=cut

## no critic(RequireFinalReturn)
sub create_testroles
{
    my ($self, %params) = @_;
    my $ret;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    my $role_structure = <<'HERE_TARGET';
	DO 
	$func$
	declare 
	    num_users_lims2 integer;
	    num_users_webapp integer;
	    num_users_testuser integer;
	    num_assignments_test_user integer;
	begin
	    SELECT count(*) 
	    into num_users_lims2
	    FROM pg_roles
	    WHERE rolname = 'lims2_test';

	    IF num_users_lims2 = 0 THEN
		CREATE ROLE "lims2_test" with encrypted password 'test_passwd' login noinherit;
	    END IF;

	    SELECT count(*) 
	    into num_users_webapp
	    FROM pg_roles
	    WHERE rolname = 'lims2_webapp';

	    IF num_users_lims2 = 0 THEN
		-- CREATE ROLE "lims2_webapp" with encrypted password 'test_passwd' login noinherit;
	    END IF;

	    SELECT count(*) 
	    into num_users_testuser
	    FROM pg_roles
	    WHERE rolname = 'test_user@example.org';

	    IF num_users_testuser = 0 THEN
		CREATE ROLE "test_user@example.org" with encrypted password 'ahdooS1e' nologin inherit;
	    END IF;

	    create temporary table tmp_role as (
	    WITH RECURSIVE is_member_of(member, roleid) AS
	       (SELECT oid, oid
		FROM pg_roles
		UNION
		SELECT m.member, r.roleid
		FROM is_member_of m JOIN
		     pg_auth_members r ON (m.roleid = r.member))
	    SELECT u.rolname, r.rolname AS belongs_to
	    FROM is_member_of m JOIN
		 pg_roles u ON (m.member = u.oid) JOIN
		 pg_roles r ON (m.roleid = r.oid)
	    where u.rolname = 'test_user@example.org'
	    or r.rolname = 'test_user@example.org'
	    )
	    ;

	    SELECT count(*) 
	    into num_assignments_test_user
	    FROM tmp_role
	    where rolname = 'test_user@example.org'
	    and belongs_to = 'lims2'
	    ;

	    IF num_assignments_test_user = 0 THEN
		grant lims2 to "test_user@example.org";
	    END IF;

	    SELECT count(*) 
	    into num_assignments_test_user
	    FROM tmp_role
	    where rolname = 'lims2_webapp'
	    and belongs_to = 'test_user@example.org'
	    ;

	    IF num_assignments_test_user = 0 THEN
		grant "test_user@example.org" to lims2_webapp;
	    END IF;

	    -- test_db_add_fixture_md5.sql:
	    CREATE TABLE fixture_md5 (
	       md5         TEXT NOT NULL,
	       created_at  TIMESTAMP NOT NULL
	    );
	    GRANT SELECT ON fixture_md5 TO "lims2_test";
	    GRANT SELECT, INSERT, UPDATE, DELETE ON fixture_md5 TO "lims2_test";
	    grant all on fixture_md5 to "lims2";
	end
	$func$
HERE_TARGET

    $ret = $self->run_query(connection => { %{$params{connection}} }, query => $role_structure);
    die "Failed to create test roles" unless ($ret);

}

## use critic

=head2 truncate_audit_tables

Truncate all records in the audit schema

=cut

## no critic(RequireFinalReturn)
sub truncate_audit_tables
{
    my ($self, %params) = @_;
    my $ret;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    my $truncate_audit_command = <<'HERE_TARGET';
	set search_path = audit, pg_catalog;
	DO
	$func$
	BEGIN
	   EXECUTE (
	      SELECT 'TRUNCATE TABLE '
		     || string_agg('audit.' || quote_ident(t.tablename), ', ')
		     || ' CASCADE'
	      FROM   pg_tables t
	      WHERE  t.schemaname = 'audit'
	   );
	END
	$func$;
HERE_TARGET

    $ret = $self->run_query(connection => { %{$params{connection}} }, query => $truncate_audit_command);
    die "Failed to create test roles" unless ($ret);

}

## use critic

=head2 create_application_role_structure

Set up all the necessary roles and relationships in a newly created database

=cut

## no critic(RequireFinalReturn)
sub create_application_role_structure
{
    my ($self, %params) = @_;
    my $ret;

    # resolve connection parameters ({entry, role} => {host, port, database, name, password})
    $self->check_connection_details(\%params);

    my $temporary_password = $self->generate_password();
    my $create_role_structure_command = <<'HERE_TARGET';
	DO
	$func$
	DECLARE
	    tc record;
	    num_users_lims2_webapp integer;
	BEGIN

	    -- ------------------------------
	    -- Create role 'lims2_webapp' if needed
	    -- ------------------------------

	    SELECT count(*)
	    INTO num_users_lims2_webapp
	    FROM pg_roles
	    WHERE rolname = 'lims2_webapp';

	    IF num_users_lims2_webapp = 0 THEN
		CREATE ROLE "lims2_webapp" WITH ENCRYPTED PASSWORD '{temporary_password}' LOGIN INHERIT;
	    END IF;

	    -- ------------------------------
	    -- Save all current role relationships
	    -- ------------------------------

	    CREATE TEMPORARY TABLE tmp_role_relationship as (
		WITH RECURSIVE is_member_of(member, roleid) AS
		    (SELECT oid, oid
			FROM pg_roles
		    UNION
		    SELECT m.member, r.roleid
		    FROM is_member_of m JOIN
			pg_auth_members r ON (m.roleid = r.member))
		SELECT u.rolname, u.rolcanlogin, r.rolname AS belongs_to
		FROM is_member_of m JOIN
		    pg_roles u ON (m.member = u.oid) JOIN
		    pg_roles r ON (m.roleid = r.oid)
		-- WHERE r.rolname LIKE 'lims2%'
		-- AND u.rolname ~ '@'
		GROUP BY u.rolname, u.rolcanlogin, r.rolname
	    )
	    ;

	    CREATE TEMPORARY TABLE tmp_applicable_users as (
		SELECT users.name
		FROM users
		JOIN pg_roles
		    ON users.name = pg_roles.rolname
		WHERE users.name ~ '@'
	    )
	    ;

	    -- ------------------------------
	    -- Grant membership to 'lims2' for all users
	    -- who haven't yet got it
	    -- ------------------------------

	    FOR tc IN
		SELECT tmp_applicable_users.name FROM tmp_applicable_users
		JOIN tmp_role_relationship
		ON tmp_applicable_users.name = tmp_role_relationship.rolname
		WHERE tmp_applicable_users.name NOT IN (
		    SELECT rolname
		    FROM tmp_role_relationship
		    WHERE belongs_to = 'lims2'
		)
		LOOP
		    EXECUTE 'GRANT "lims2" TO "' || tc.name || '" ;'
		    ;
		END LOOP
	    ;


	    -- ------------------------------
	    -- Grant membership from 'lims2_webapp' for all users
	    -- who haven't yet got it
	    -- ------------------------------

	    FOR tc IN
		SELECT DISTINCT tmp_applicable_users.name FROM tmp_applicable_users
		JOIN tmp_role_relationship
		ON tmp_applicable_users.name = tmp_role_relationship.belongs_to
		WHERE tmp_applicable_users.name NOT IN (
		    SELECT belongs_to
		    FROM tmp_role_relationship
		    WHERE rolname = 'lims2_webapp'
		)
		LOOP
		    EXECUTE 'GRANT "' || tc.name || '" TO lims2_webapp ;'
		    ;
		END LOOP
	    ;

	END
	$func$;
HERE_TARGET

    $create_role_structure_command =~ s/{temporary_password}/$temporary_password/g;
    $ret = $self->run_query(connection => { %{$params{connection}} }, query => $create_role_structure_command);
    die "Failed to create test roles" unless ($ret);

}

## use critic



=head2 clone_database

Create a new database based on the content in a separate database.
 1. The schema is copied out without any role or ownership information
 2. The schema is 'doctored' to change database name and procedural language creation
     (using pg_dump and pg_restore allows database renaming, but cannot control plpgsql language creation)
 3. The schema is loaded into the target server
 4. The data is copied over
 5. A new role structure is created

=cut

## no critic(ProhibitExcessComplexity)
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
    if (!exists($params{keep_temporary_files}))
    {
	$params{keep_temporary_files} = 0;
    }
    $params{keep_temporary_files} ||= $self->overwrite;

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
    $source_definition_dumpfile = $self->dump_database_definition(connection => $source_connection_details, role => $params{source_role}, no_role => $params{no_source_role}, with_data => 0, keep_temporary_files => $params{keep_temporary_files} );
    die "Failed to create a database definition dump" unless ((-e $source_definition_dumpfile) && (-s $source_definition_dumpfile));
    # Amend the definition
    {
	## no critic(RequireBriefOpen)
	local $/ = undef;
	open (my $FH, "+<", $source_definition_dumpfile) or die "Opening: $!";
	my $content = <$FH>;
	$content =~ s/Name: $source_connection_details->{dbname};/Name: $params{destination_db};/g;
	$content =~ s/CREATE DATABASE $source_connection_details->{dbname}/CREATE DATABASE $params{destination_db}/g;
	$content =~ s/\\connect $source_connection_details->{dbname}/\\connect $params{destination_db}/g;
	$content =~ s/CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;/-- CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;/g;
	$content =~ s/CREATE EXTENSION IF NOT EXISTS plpgsql/-- CREATE EXTENSION IF NOT EXISTS plpgsql/g;
	$content =~ s/COMMENT ON EXTENSION plpgsql/-- COMMENT ON EXTENSION plpgsql/g;
	seek($FH, 0, 0) or die "Seeking: $!";
	print $FH $content or die "Printing: $!";
	truncate($FH, tell($FH)) or die "Truncating: $!";
	close($FH) or die "Closing: $!";
	## use critic
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
	$ret = $self->truncate_audit_tables(connection => { %{$destination_connection_details}, dbname => $params{destination_db}});
	die "Failed to truncate audit tables" unless ($ret);

    }

    # Restore a minimum set of test roles
    if ($params{create_test_role}) {
	$self->create_testroles(connection => { %{$destination_connection_details}, dbname => $params{destination_db}});
    }

    # Finally, set up a set of roles
    $ret = $self->create_application_role_structure(connection => { %{$destination_connection_details}, dbname => $params{destination_db}});

    return 1;

}
## use critic

=head2 generate_password

Create a temporary password.
Used in the setting up of new database environment,
where we need an initial password that can later be overriden.
( cut down version of LIMS2::Template::Plugin::PasswordGenerator )

=cut

sub generate_password {
    my ($self) = @_;
    my $pw_len = 12;
    my $pw_chars = [ "A" .. "Z", "a" .. "z", "0" .. "9" ];

    return join '', map { $pw_chars->[ int rand @{$pw_chars} ] } 1 .. $pw_len;
}

1;

=head1 LICENSE

package LIMS2::Template::Plugin::PasswordGenerator;

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__

