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
use LIMS2::Model::Util::ImportCrispressoQC qw( get_data_from_file );

#ENTRY
my $model = LIMS2::Model->new({ user => 'tasks' });
open (my $fh, '<:encoding(UTF-8)', 'files_paths.txt') or die 'Cannot open files_paths.txt to read';
chomp(my @lines = <$fh>);
close($fh);

while (@lines){ #foreach file from the list of file directories
    my $file = shift @lines;
    get_data_from_file ($model, $file );
}

=head1 NAME

create_miseq_well_exps.pl - runs through a list of miseq alleles frequencies 
and creates miseq well experiments database entries for each one of them.

=head1 SYNOPSIS

Requires a txt file with paths to alleles frequency table files. For each one 
of those files, looks up the correspoding miseq well experiment. If one does not
exist in the database, it creates an entry for it.

=head1 DESCRIPTION

This script is used to fill the database with information regarding all the miseq well experiments,
that exist in the local file system. It is meant to be used right before the migration_script.pl script. 
Running it first, makes the whole data migration process much faster, as it saves time from reloading cache
each time.
