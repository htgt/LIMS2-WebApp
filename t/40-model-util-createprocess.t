#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most;
use Try::Tiny;
use DateTime;

use Data::Dumper;

note("Testing creation of process cell line list");

{	
	ok my $fields = model->get_process_fields( { process_type => 'first_electroporation'} ), 
	   'fep fields generated';
	is_deeply($fields->{'cell_line'}->{'values'}, ['oct4:puro iCre/iFlpO #11'], 'cell line list correct');
}

done_testing();