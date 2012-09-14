#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

use LIMS2::Test;
use Test::Most;

BEGIN {
    use_ok('LIMS2::Model::Util::CreateProcess', qw( process_plate_types ) );
}

note("Testing creation of process cell line list");

{
	ok my $fields = model->get_process_fields( { process_type => 'first_electroporation'} ),
	   'fep fields generated';
	is_deeply($fields->{'cell_line'}->{'values'}, ['oct4:puro iCre/iFlpO #11'], 'cell line list correct');
}

note("Testing plate type check for process which can have any plate type output");

{
    ok my $process_plate_types = process_plate_types( model, 'rearray' );
    my $all_plate_types = [ map{ $_->id } @{ model->list_plate_types } ];
    is_deeply $process_plate_types, $all_plate_types, 'list all plate types for process not in hash';

}
done_testing();
