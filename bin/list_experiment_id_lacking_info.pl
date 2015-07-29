#!/usr/bin/env perl
#Shebang informs the shell of intended language
#If Database.pm is missing, lims2 show
use strict;
use warnings;

use Log::Log4perl qw( :easy );
use Data::Dumper;
use Data::Compare;
use feature qw(say);
use Spreadsheet::XLSX;
use LIMS2::Model;
use Try::Tiny;
use Text::CSV;

my $model = LIMS2::Model->new( user => 'lims2' );

#Read in the XLSX file
my $gene_sheet = Spreadsheet::XLSX -> new ("/nfs/users/nfs_p/pk8/dev/LIMS2-WebApp/bin/crispr_genes.xlsx");
my @gene_ids;

#Place gene_ids into an array
foreach my $sheet (@{$gene_sheet -> {Worksheet}}) {
    $sheet -> {MaxRow} ||= $sheet -> {MinRow};
    foreach my $row ($sheet -> {MinRow} .. $sheet -> {MaxRow}) {
        $sheet -> {MaxCol} ||= $sheet -> {MinCol};
        foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
            my $cell = $sheet -> {Cells} [$row] [$col];
            if ($cell) {
                push @gene_ids, $cell -> {Val};
            }
        }
    }
}

#Pop and discard the first item which is a title 
shift @gene_ids;
foreach my $item (@gene_ids)
{
    print $item, "\n";
}
print "\n-------------------------------------------------\n";

#Define storage of gene_symbol, experiment_id, sequence

my $gene_info;
my @projects;
my $species_id = 'Mouse';

my $csv = Text::CSV->new({ binary => 1, auto_diag => 1, eol => "\n"})
        or die "Cannot use CSV: " . Text::CSV->error_diag();

$csv->column_names('Gene_Symbol', 'Experiment_ID', 'Crispr_ID', 'Sequence');
my $fh;
open $fh, ">", "results.csv" or die "Failed: $!";

foreach my $item (@gene_ids)
{
    $gene_info = try {
        $model->find_gene( { search_term => $item, species => $species_id })
    } catch {
        print "\nGene not found.";
    };

    @projects = try {
        $model->schema->resultset('Project')->search({
            gene_id => $gene_info->{'gene_id'},
        });
    } catch {
        print "\nProjects not found.";
    };

    foreach my $project (@projects)
    {
        my $exp_hash_ref = try {
            $model->schema->resultset('Experiment')->search({
                project_id => $project->as_hash->{'id'},
            });
        } catch {
            print "\nExperiments not found.";
        };

        while (my $exp = $exp_hash_ref->next){
            $exp = $exp->as_hash_with_detail;
            compress_data($exp, $gene_info->{'gene_symbol'}, $csv, $fh);
        }
    }
}
close $fh;

sub compress_data{
    my ($exp_data, $gene_symbol, $csv_file, $file_h) = @_;
    foreach my $crispr ($exp_data->{'crisprs'}){
        for (my $i = 0; $i<4; $i++){
            print "\n Gene_Symbol: ", $gene_symbol, " Experiment_id: ", $exp_data->{'id'}," Crispr: ", $crispr->[$i]->{'id'}, " Seq: ", $crispr->[$i]->{'seq'}, "\n";
            write_data($gene_symbol, $exp_data->{'id'}, $crispr->[$i]->{'id'}, $crispr->[$i]->{'seq'}, $csv_file, $file_h);
        }
    }
    return
}

sub write_data{
    my ($gene_symbol, $exp_id, $crispr, $seq, $csv_f, $file_handle) = @_;

    $csv_f->print($file_handle,[$gene_symbol, $exp_id, $crispr, $seq]);
    return
}
