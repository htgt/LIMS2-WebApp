#!/usr/bin/env perl

# NB: TryCatch blocks in the Schema/Result modules cause schema dump
# to fail with an error like this:
#
# PL_linestr not long enough, was Devel::Declare loaded soon enough in (eval 1152)
#

# Solution is to use Try::Tiny instead


use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use DBIx::Class::Schema::Loader 'make_schema_at';
use FindBin;
use Path::Class;
use Term::ReadPassword qw( read_password );

my %MONIKER_MAP = (
    # Singular problems
    bac_clone_loci              => 'BacCloneLocus',
    design_oligo_loci           => 'DesignOligoLocus',
    crispr_loci                 => 'CrisprLocus',
    qc_seq_reads                => 'QcSeqRead',
    qc_runs                     => 'QcRun',
    crispr_off_target_summaries => 'CrisprOffTargetSummary',
    crispr_es_qc_runs           => 'CrisprEsQcRuns',
);

my %REL_NAME_MAP = (
    # Bad plurals, prefer shorter method name
    Assembly => {
        design_oligo_locis  => 'design_oligo_loci',
        crisprs_off_targets => 'crispr_off_targets',
        bac_clone_locis     => 'bac_clone_loci',
        crispr_locis        => 'crispr_loci',
    },
    BacClone => {
        bac_clone_locis => 'loci'
    },
    Chromosome => {
        design_oligo_locis  => 'design_oligo_loci',
        crisprs_off_targets => 'crispr_off_targets',
        bac_clone_locis     => 'bac_clone_loci',
        crispr_locis        => 'crispr_loci',
    },
    Crispr => {
        crispr_locis                 => 'loci',
        crisprs_off_targets          => 'off_targets',
        crisprs_off_target_summaries => 'off_target_summaries',
        designs                      => 'nonsense_designs',
        crisprs                      => 'nonsense_crisprs',
    },
    CrisprLociType => {
        crisprs_off_targets => 'crispr_off_targets',
    },
    CrisprPrimer => {
        crispr_primers_locis         => 'crispr_primer_loci',
    },
    Design => {
        design_oligos   => 'oligos',
        design_comments => 'comments',
        design_type     => 'type',
        gene_designs    => 'genes'
    },
    DesignOligo => {
        design_oligo_locis => 'loci'
    },
    GenotypingPrimer => {
        genotyping_primers_locis     => 'genotyping_primer_loci',
    },
    QcSeqProject => {
        qc_seqs_reads        => 'qc_seq_reads',
        qc_seq_projects_well => 'qc_seq_project_wells'
    },
    QcRunSeqWell => {
        qc_run_seq_well_qc_seqs_read => 'qc_run_seq_well_qc_seq_reads'
    },
    QcTemplate => {
        qcs_runs => 'qc_runs'
    },
    Species => {
        species_default_assembly => 'default_assembly'
    },
    User => {
        qcs_runs => 'qc_runs'
    },
    Process => {
        process_inputs_well => 'process_input_wells',
        process_outputs_well => 'process_output_wells',
        wells => 'input_wells',
        input_wells_2s => 'output_wells',
    },
    Well => {
        process_inputs_well => 'process_input_wells',
        process_outputs_well => 'process_output_wells',
        processes => 'input_processes',
        input_processes_2s => 'output_processes',
    }
    # Bad plurals
    #bac_clone_locis        => 'bac_clone_loci',
    #design_oligo_locis     => 'design_oligo_loci',
    # Clashes with column names
    # assembly               => 'assembly_rel',
    # design_type            => 'design_type_rel',
    # chr_name               => 'chromosome',
    # library                => 'bac_library_rel',
    # design_oligo_type      => 'design_oligo_type_rel',
    # type                   => 'genotyping_primer_type_rel',
    # plate_type             => 'plate_type_rel',
    # process_type           => 'process_type_rel',
);

my $pg_host      = $ENV{PGHOST};
my $pg_port      = $ENV{PGPORT};
my $pg_database  = $ENV{PGDATABASE};
my $pg_schema    = 'public';
my $pg_user      = $ENV{USER};
my $pg_role      = undef;
my $schema_class = 'LIMS2::Model::Schema';
my $lib_dir      = dir( $FindBin::Bin )->parent->subdir( 'lib' );
my $overwrite    = 0;
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
    'overwrite!'     => \$overwrite,
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

my %make_schema_opts = (
    debug              => 0,
    dump_directory     => $lib_dir->stringify,
    db_schema          => $pg_schema,
    components         => \@components,
    use_moose          => 1,
    moniker_map        => \%MONIKER_MAP,
    rel_name_map       => \%REL_NAME_MAP,
    exclude            => qr/fixture_md5/,
    skip_load_external => 1
);

if ( $overwrite ) {
    $make_schema_opts{overwrite_modifications} = 1;
}

make_schema_at(
    $schema_class,
    \%make_schema_opts,
    [ $dsn, $pg_user, $pg_password, {}, \%opts ]
);
