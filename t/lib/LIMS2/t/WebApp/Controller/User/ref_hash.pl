#!/usr/bin/perl

use warnings;
use diagnostics;

my $ref = {
	
    one => 'uno',
    two => 'dos',
    three => 'tres'
};

foreach my $k (sort keys %{$ref}){

print "$k : ${$ref}{$k}";

}
