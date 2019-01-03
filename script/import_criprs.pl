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
use LIMS2::Model::Util::ImportCrispressoQC qw( get_data_from_file get_crispr migrate_crispresso_subs);

#ENTRY
my $model = LIMS2::Model->new({ user => 'tasks' });

open (my $th, '<:encoding(UTF-8)', 'files_paths.txt') or die 'Cannot open files_paths.txt to read';
chomp(my @lines = <$th>);
close($th);

while (@lines){ #foreach file from the list of file directories
    my $line = shift @lines;

    my $data = get_data_from_file ($model, $line);
    unless ($data->{miseq_well_experiment}->{total_reads}){
        open (my $th, '>>', 'error_log.txt') or die;
        say $th $line;
        close $th;
        print Dumper "SKIPPED FILE: $line";
        next;
    }

    my $jobout = $line;
    $jobout =~ s/CRISPR\S*txt/job.out/g;
    next unless (-e $jobout);
    migrate_crispresso_subs($model, $jobout, $data);

}
