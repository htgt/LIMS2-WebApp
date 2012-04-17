#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use DBI;
use Data::Dump 'dd';
use Getopt::Long;
use Const::Fast;
use Term::ReadPassword;
use Template;
use Getopt::Long;

const my $MAIN_SCHEMA  => 'public';
const my $AUDIT_SCHEMA => 'audit';

const my $CREATE_AUDIT_TABLE_TT => <<'EOT';
CREATE TABLE [% audit_schema %].[% table_name %] (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
[% column_spec.join(",\n") %]
);
GRANT SELECT ON [% audit_schema %].[% table_name %] TO [% ro_role %];
GRANT SELECT,INSERT ON [% audit_schema %].[% table_name %] TO [% rw_role %];
EOT

const my $CREATE_AUDIT_FUNCTION_TT => <<'EOT';
CREATE OR REPLACE FUNCTION [% main_schema %].process_[% table_name %]_audit()
RETURNS TRIGGER AS $[% table_name %]_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO [% audit_schema %].[% table_name %] SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO [% audit_schema %].[% table_name %] SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO [% audit_schema %].[% table_name %] SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$[% table_name %]_audit$ LANGUAGE plpgsql;
EOT

const my $CREATE_AUDIT_TRIGGER_TT => <<'EOT';
CREATE TRIGGER [% table_name %]_audit
AFTER INSERT OR UPDATE OR DELETE ON [% main_schema %].[% table_name %]
    FOR EACH ROW EXECUTE PROCEDURE [% main_schema %].process_[% table_name %]_audit();
EOT

const my $DROP_AUDIT_TABLE_COLUMN_TT => <<'EOT';
ALTER TABLE [% audit_schema %].[% table_name %] DROP COLUMN [% column_name %];
EOT

const my $ADD_AUDIT_TABLE_COLUMN_TT => <<'EOT';
ALTER TABLE [% audit_schema %].[% table_name %] ADD COLUMN [% column_name %] [% column_type %];
EOT

const my $DROP_AUDIT_TABLE_TT => <<'EOT';
DROP TABLE [% audit_schema %].[% table_name %];
EOT

const my %IS_AUDIT_COL => map { $_ => 1 } qw( audit_op audit_user audit_stamp audit_txid );

const my %NEEDS_SIZE => map { $_ => 1 } qw( char character varchar );

my $pg_host   = $ENV{PGHOST};
my $pg_port   = $ENV{PGPORT};
my $pg_dbname = $ENV{PGDATABASE};
my $pg_role;

GetOptions(
    'host=s'    => \$pg_host,
    'port=s'    => \$pg_port,
    'dbname=s'  => \$pg_dbname,
    'role=s'    => \$pg_role
) or die "Usage: $0 [OPTIONS]\n";

$pg_role ||= $pg_dbname . '_ro';

my $pg_password;
while( not defined $pg_password ) {
    $pg_password = read_password( "Enter PostgreSQL password for $ENV{USER}: " );
}

my $dsn = 'dbi:Pg:dbname=' . $pg_dbname;

if ( defined $pg_host ) {
    $dsn .= ";host=" . $pg_host;
}

if ( defined $pg_port ) {
    $dsn .= ";port=" . $pg_port;
}

my $dbh = DBI->connect( $dsn, $ENV{USER}, $pg_password, { AutoCommit => 1, RaiseError => 1, PrintError => 0 } )
    or die "Failed to connect to $dsn: $DBI::errstr\n";

$dbh->do( 'SET SESSION ROLE ' . $dbh->quote_identifier( $pg_role ) );

const my %VARS => (
    main_schema  => $MAIN_SCHEMA,
    audit_schema => $AUDIT_SCHEMA,
    ro_role      => $pg_dbname . '_ro',
    rw_role      => $pg_dbname . '_rw'
);

my $tt = Template->new;

my $main_tables   = get_tables( $dbh, $MAIN_SCHEMA );
my $audit_tables  = get_tables( $dbh, $AUDIT_SCHEMA );

while ( my ( $table_name, $main_table ) = each %{ $main_tables } ) {
    my $audit_table = $audit_tables->{$table_name};
    if ( $audit_table ) {
        diff_tables( $table_name, $main_table, $audit_table );
    }
    else {
        initialize_auditing( $table_name, $main_table );
    }
}

for my $table_name ( keys %{$audit_tables} ) {
    unless ( $main_tables->{$table_name} ) {
        $tt->process( \$DROP_AUDIT_TABLE_TT, { %VARS, table_name => $table_name } );
    }
}

sub diff_tables {
    my ( $table_name, $col_spec, $audit_col_spec ) = @_;

    my %vars = ( %VARS, table_name => $table_name );

    my %cols       = map { @{$_} } @{$col_spec};
    my %audit_cols = map { @{$_} } @{$audit_col_spec};

    for my $cs ( @{$col_spec} ) {
        my ( $column_name, $column_type ) = @{$cs};
        my $audit_column_type = $audit_cols{$column_name};
        if ( $audit_column_type ) {
            if ( $audit_column_type ne $column_type ) {
                warn "Table $table_name column $column_name type mismatch ($column_type vs $audit_column_type)\n";
            }
        }
        else {
            $tt->process( \$ADD_AUDIT_TABLE_COLUMN_TT, { %vars, column_name => $column_name, column_type => $column_type } );
        }        
    }

    for my $audit_column_name ( keys %audit_cols ) {
        unless ( $cols{$audit_column_name} or exists $IS_AUDIT_COL{$audit_column_name} ) {
            $tt->process( \$DROP_AUDIT_TABLE_COLUMN_TT, { %vars, column_name => $audit_column_name } );
        }
    }
}

sub initialize_auditing {
    my ( $table_name, $col_spec ) = @_;

    my %vars = (
        %VARS,
        table_name  => $table_name,
        column_spec => [ map { join q{ }, @{$_} } @{$col_spec} ]
    );

    $tt->process( \$CREATE_AUDIT_TABLE_TT,    \%vars );
    $tt->process( \$CREATE_AUDIT_FUNCTION_TT, \%vars );
    $tt->process( \$CREATE_AUDIT_TRIGGER_TT,  \%vars );
}

sub get_tables {
    my ( $dbh, $schema_name ) = @_;

    my $sth = $dbh->table_info( undef, $schema_name, undef, 'TABLE' );
    
    my %tables;
    
    while ( my $r = $sth->fetchrow_hashref ) {
        $tables{ $r->{TABLE_NAME} } = get_column_info( $dbh, $schema_name, $r->{TABLE_NAME} );        
    }

    return \%tables;
}

sub get_column_info {
    my ( $dbh, $schema_name, $table_name ) = @_;

    my @column_info;
    
    my $sth = $dbh->column_info( undef, $schema_name, $table_name, undef );
    while ( my $r = $sth->fetchrow_hashref ) {
        my $type = $r->{TYPE_NAME};
        if ( exists $NEEDS_SIZE{$type} ) {
            $type = $type . '(' . $r->{COLUMN_SIZE} . ')';
        }        
        push @column_info, [ $r->{COLUMN_NAME}, $type ];        
    }

    return \@column_info;
}

