#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';
use JSON;

my $mech = mech();


my $plate = "SEP0006";

$mech->get_ok('/api/well/genotyping_qc?plate_name='.$plate, 
             {'content-type' => 'application/json'} );

ok my $json = decode_json($mech->content), 'can decode json response';

my $well_data = $json->[0];

is $well_data->{plate_name}, $plate, 'wells are from correct plate';

ok exists($well_data->{laczconfidence}), 'lacz confidence retrieved';

is $well_data->{targeting_pass}, undef, 'targeting pass currently undefined';

$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id},
             {'content-type' => 'application/json', 'content' => '{"targeting_pass":"passb"}' },
             );
             
ok my $well_targ_pass = model->retrieve_well_targeting_pass({ id => $well_data->{id} }), 'retrieved new well targeting pass';

is $well_targ_pass->result, 'passb', 'well targeting pass updated to passb';

done_testing();