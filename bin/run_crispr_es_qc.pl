#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use LIMS2::Model::Util::CrisprESQC;
use Getopt::Long;
use Log::Log4perl ':easy';
use Pod::Usage;
use feature qw( say );

my $log_level = $WARN;
my ($plate_name,          $well_name,          $forward_primer_name,
    $reverse_primer_name, $sequencing_project, $dir,
    $commit,              $seq_plate,          $sequencing_fasta
);
GetOptions(
    'help'                  => sub { pod2usage( -verbose    => 1 ) },
    'man'                   => sub { pod2usage( -verbose    => 2 ) },
    'debug'                 => sub { $log_level = $DEBUG },
    'verbose'               => sub { $log_level = $INFO },
    'plate_name=s'          => \$plate_name,
    'well_name=s'           => \$well_name,
    'forward_primer_name=s' => \$forward_primer_name,
    'reverse_primer_name=s' => \$reverse_primer_name,
    'sequencing_project=s'  => \$sequencing_project,
    'sequencing_fasta=s'    => \$sequencing_fasta,
    'dir=s'                 => \$dir,
    'commit'                => \$commit,
    'seq_plate=s'           => \$seq_plate,
) or pod2usage(2);

die('Must specify a plate name') unless $plate_name;

Log::Log4perl->easy_init( { level => $log_level, layout => '%p %m%n' } );

my $model = LIMS2::Model->new( user => 'lims2' );

my $plate = $model->retrieve_plate( { name => $plate_name  } );

# TEMP hack, should not really hard code all these values
my $cigar_parser = HTGT::QC::Util::CigarParser->new(
        primers => [ 'SPF', 'SPR', 'SF1', 'SR1' ] );

my %params = (
    model                   => $model,
    plate                   => $plate,
    sequencing_project_name => $sequencing_project,
    forward_primer_name     => $forward_primer_name,
    reverse_primer_name     => $reverse_primer_name,
    species                 => 'Human',
    base_dir                => $dir,
    commit                  => $commit,
    cigar_parser            => $cigar_parser,
);
$params{well_name} = $well_name if $well_name;
$params{sequencing_plate} = $seq_plate if $seq_plate;
$params{sequencing_fasta} = $sequencing_fasta if $sequencing_fasta;

my $qc_runner = LIMS2::Model::Util::CrisprESQC->new( %params );

my $qc_run = $qc_runner->analyse_plate;

if ( $qc_run ) {
    say 'Qc analysis done, run id: ' . $qc_run->id;
}
