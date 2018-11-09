#!/usr/bin/env perl 

use strict;
use warnings FATAL => 'all';
use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Moose;
use Text::CSV;
use LIMS2::Model::Util::Miseq qw( miseq_well_processes convert_index_to_well_name );
use List::Compare::Functional qw( get_intersection );
use LIMS2::Model::Util::ImportCrispressoQC qw( get_data_from_file get_crispr );

#ENTRY
my $model = LIMS2::Model->new({ user => 'tasks' });

open (my $th, '<:encoding(UTF-8)', 'files_paths.txt') or die 'Cannot open files_paths.txt to read';

my $csv = Text::CSV->new( { binary => 1, sep_char => q/,/, eol => "\n" } );
open my $ch, '>', 'criprs.csv' or die 'Could not create example file';
$csv->print( $ch, [qw/Experiment Well Crispr NHEJ Total Efficiency Date/] );
close($ch);

while (my $file = <$th>){ #foreach file from the list of file directories
    chomp $file;
    my $data = get_data_from_file ($model, $file );
    unless ($data->{miseq_well_experiment}->{total_reads}){
        open (my $th, '>>', 'error_log.txt') or die;
        say $th $file;
        close $th;
        print Dumper "SKIPPED FILE: $file";
        next;
    }

    my $jobout = $file;
    $jobout =~ s/CRISPR\S*txt/job.out/g;
    next unless (-e $jobout);
    my $job = get_crispr($jobout);
    my $efficiency = sprintf("%.2f", $data->{miseq_well_experiment}->{nhej_reads} / $data->{miseq_well_experiment}->{total_reads} * 100) ."%";
    my @array = (
            $data->{miseq_experiment}->{name},
            $data->{miseq_well_experiment}->{well_name},
            $job ->{crispr},
            $data->{miseq_well_experiment}->{nhej_reads},
            $data->{miseq_well_experiment}->{total_reads},
            $efficiency,
            $job->{date}
    );

    open my $fh, '>>', 'criprs.csv' or die 'Could not open crispr file';
    $csv->print($fh, \@array);
    print Dumper "WROTE FILE: $file";
    close($ch);
}
close($th);
