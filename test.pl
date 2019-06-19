#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $letter = 'A';
foreach ( 1 .. 5 ) {
    print "${letter}\n";
    $letter++;
}
