#!/usr/bin/env perl 

use strict;
use warnings FATAL => 'all';
use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use Try::Tiny;
use Moose;
use Text::CSV;

my @files = `find /warehouse/team229_wh01/lims2_managed_miseq_data/. -name job.out`;

open (my $fh, '>', 'job_out_paths.txt') or die 'Cannot open files_location.txt to write';

foreach my $file ( @files ){
    print $fh $file;
}
close($fh);
