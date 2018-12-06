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
use LIMS2::Model::Util::ImportCrispressoQC qw( get_data_from_file get_crispr migrate_histogram);

#ENTRY
my $model = LIMS2::Model->new({ user => 'tasks' });

open (my $th, '<:encoding(UTF-8)', 'files_paths.txt') or die 'Cannot open files_paths.txt to read';
chop(my @lines = <$th>);
close($th);
while (@lines){ #foreach file from the list of file directories
    my $file = shift @lines;
    my $data = get_data_from_file ($model, $file);
    next unless $data;

    my $path_to_histogram = $file;
    $path_to_histogram =~ s/Alleles_frequency_table/indel_histogram/g;
    
    migrate_histogram( $model, $path_to_histogram, $data->{miseq_well_experiment}, $file );
}
