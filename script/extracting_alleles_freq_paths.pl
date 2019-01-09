#!/usr/bin/env perl 

use strict;
use warnings FATAL => 'all';
use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Moose;
use Text::CSV;

my @files = `find /warehouse/team229_wh01/lims2_managed_miseq_data/. -name Alleles_frequency_table.txt`;

open (my $fh, '>', 'files_paths.txt') or die 'Cannot open files_location.txt to write';

foreach my $file ( @files ){
    print $file;
    print $fh $file;
}
close($fh);

=head1 NAME

extracting_alleles_freq_paths.pls - 

=head1 SYNOPSIS

Grabs the local path of each alleles frequency txt file from the file system and saves it in a .txt file.

=head1 DESCRIPTION

This script is used to produce the files_path.txt file required for many of the database migration scripts.
It grabs the paths to each of the miseq alleles frequency table txt files. 
Those paths are very helpful since they hold information regarding the ids of miseq, well and experiment for each allele.
