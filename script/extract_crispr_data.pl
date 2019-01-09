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
chop(my @lines = <$th>);
close($th);

my $csv = Text::CSV->new( { binary => 1, sep_char => q/,/, eol => "\n" } );
open my $ch, '>', 'criprs.csv' or die 'Could not create example file';
$csv->print( $ch, [qw/Experiment MiseqPlate Well Crispr Aligned_Sequence Number_Of_Reads Percentage Date/] );
close($ch);

while (@lines){ #foreach file from the list of file directories
    my $file = shift @lines;
    my $data = get_data_from_file ($model, $file );
    unless ($data->{miseq_well_experiment}->{total_reads}){
        open (my $th, '>>', 'error_log.txt') or die;
        say $th $file;
        close $th;
        print Dumper "SKIPPED FILE: $file";
        next;
    }
    my $rs = $model->schema->resultset('MiseqAllelesFrequency')->search({ miseq_well_experiment_id => $data->{miseq_well_experiment}->{id} });
    my @rows = $rs->all;

    while (@rows) {
        my $temp = shift @rows;
        my %frequency = $temp->get_columns;

        my $percentage = $frequency{n_reads} / $data->{miseq_well_experiment}->{total_reads};
        if ( $percentage < 0.05 ) {
            next;
        }
        $percentage = sprintf("%.2f", $percentage * 100) ."%";
        my $jobout = $file;
        $jobout =~ s/CRISPR\S*txt/job.out/g;
        next unless (-e $jobout);
        my $job = get_crispr($jobout);
        my @array = (
                $data->{miseq_experiment}->{name},
                $data->{miseq_plate}->{name},
                $data->{miseq_well_experiment}->{well_name},
                $job->{crispr},
                $frequency{aligned_sequence},
                $frequency{n_reads},
                $percentage,
                $job->{date}
        );

        open my $fh, '>>', 'criprs.csv' or die 'Could not open crispr file';
        $csv->print($fh, \@array);
        print Dumper "WROTE FILE: $file";
        close($fh);
    }
}
close($th);


=head1 NAME

extract_crispr_data.pl - extract crispr data in a csv format

=head1 SYNOPSIS

This script is going through the database and the files in order to collect data for each allele loaded in the system.
It then creates a csv with all the relevant data, as requested by the lab. More information can be found in the description section of the pod.
The script takes in txt file that should be in the directory the user is running the script from, called files_path.txt. The file needs to have 
the paths to the local files from any miseq run. For example:
/warehouse/team229_wh01/lims2_managed_miseq_data/./Miseq_020/S82_expZcchc6_1_384/CRISPResso_on_466_S466_L001_R1_001_466_S466_L001_R2_001/Alleles_frequency_table.txt

=head1 DESCRIPTION

Following some analysis done the lab, it seems that the activity of eSpCas9_1.1 (the enzyme we use) depends on the nature of the first base of the 
guide. This analysis has been done with a self-targeting library, so we would like to see if the same applies to our own protein-based experiments 
in iPSCs.

We would therefore like to collect information on the efficiency of editing for each guide that we have used with the eSpCas9 enzyme from the MiSeq
data, stratified by whether they use the two-part crRNA/tracrRNA or single part sgRNA guides. This would ideally be a total number of edited alleles
as a percentage (e.g. 10x homozygotes, 20x heterozygotes and 70x WT would be (10x2)+(20x1) divided by 100x2 = 40/200 = 20%). If it’s easier, a good
proxy would simply be the (total number of NHEJ reads) / (total number of reads) across the wells that correspond to that particular CRISPR, but it
would be better to do it per allele if possible, since the number of reads per well is somewhat variable.

=head1 AUTHOR

Anna Farne
