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
use LIMS2::Model::Util::ImportCrispressoQC.pl;


#ENTRY
my $model = LIMS2::Model->new({ user => 'tasks' });

open (my $fh, '<:encoding(UTF-8)', 'files_paths.txt') or die 'Cannot open files_paths.txt to read';

while (my $file = <$fh>){ #foreach file from the list of file directories
    chomp $file;
    my $data = extract_data_from_path( $model, $file );
}
