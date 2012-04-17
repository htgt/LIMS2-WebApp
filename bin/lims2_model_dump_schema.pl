#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use DBIx::Class::Schema::Loader 'make_schema_at';
use FindBin;
use Path::Class;
use Term::ReadPassword qw( read_password );

my %MONIKER_MAP = (
    # Singular problems
    bac_clone_loci    => 'BacCloneLocus',
    design_oligo_loci => 'DesignOligoLocus',
    qc_seq_reads      => 'QcSeqRead',
);

my %REL_NAME_MAP = (
    # Bad plurals, prefer shorter method name
    BacClone => {
        bac_clone_locis => 'loci'
    },
    DesignOligo => {
        design_oligo_locis => 'loci'
    },
    QcSequencingProject => {
        qc_seqs_reads => 'qc_seq_reads'
    },
    # Bad plurals
    bac_clone_locis        => 'bac_clone_loci',
    design_oligo_locis     => 'design_oligo_loci',
    # Clashes with column names
    assembly               => 'assembly_rel',
    design_type            => 'design_type_rel',
    chr_name               => 'chromosome',
    library                => 'bac_library_rel',
    design_oligo_type      => 'design_oligo_type_rel',
    type                   => 'genotyping_primer_type_rel',
    plate_type             => 'plate_type_rel',
    process_type           => 'process_type_rel',
    qc_sequencing_project  => 'qc_sequencing_project_rel',
);

my $pg_host      = $ENV{PGHOST};
my $pg_port      = $ENV{PGPORT};
my $pg_database  = $ENV{PGDATABASE};
my $pg_schema    = 'public';
my $pg_user      = $ENV{USER};
my $pg_role      = undef;
my $schema_class = 'LIMS2::Model::Schema';
my $lib_dir      = dir( $FindBin::Bin )->parent->subdir( 'lib' );
my @components   = qw( InflateColumn::DateTime );

GetOptions(
    'host=s'         => \$pg_host,
    'port=s'         => \$pg_port,
    'dbname=s'       => \$pg_database,
    'user=s'         => \$pg_user,
    'role=s'         => \$pg_role,
    'schema=s'       => \$pg_schema,
    'schema-class=s' => \$schema_class,
    'lib-dir=s'      => \$lib_dir,
    'component=s@'   => \@components,
) or die "$0 [OPTIONS]\n";

my $dsn = 'dbi:Pg:dbname=' . $pg_database;

if ( defined $pg_host ) {
    $dsn .= ";host=" . $pg_host;
}

if ( defined $pg_port ) {
    $dsn .= ";port=" . $pg_port;
}

my $pw_prompt = sprintf( 'Enter password for %s%s: ', $pg_user, defined $pg_host ? '@'.$pg_host : '' );
my $pg_password;
while ( not defined $pg_password ) {
    $pg_password = read_password( $pw_prompt );
}

my %opts;

if ( $pg_role ) {
    die "Invalid role: $pg_role" if $pg_role =~ m/\"/;
    $opts{on_connect_do} = [ sprintf( 'SET ROLE "%s"', $pg_role ) ];
}

make_schema_at(
    $schema_class,
    {   debug          => 0,
        dump_directory => $lib_dir->stringify,
        db_schema      => $pg_schema,
        components     => \@components,
        use_moose      => 1,
        moniker_map    => \%MONIKER_MAP,
        rel_name_map   => \%REL_NAME_MAP
    },
    [ $dsn, $pg_user, $pg_password, {}, \%opts ]
);

