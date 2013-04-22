#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';
use JSON;

my $mech = mech();


my $plate = 'SEP0006';


$mech->get_ok('/api/well/genotyping_qc?plate_name='.$plate, 
             {'content-type' => 'application/json'} );

ok my $json = decode_json($mech->content), 'can decode json response';

my $well_data = $json->[0];

is $well_data->{plate_name}, $plate, 'wells are from correct plate';

ok exists($well_data->{'lacz#confidence'}), 'lacz confidence retrieved';

is $well_data->{targeting_pass}, '-', 'targeting pass currently undefined';
# FIXED: plate_name was coming back as undef, but in production plate_name is valid.
# We are now using plate_name to limit the query search, which we weren't before.
# Thus the test passed in the previous releases, without plate name in the URI.
# Now iit plate_name is required.
#
$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
             {'content-type' => 'application/json', 'content' => '{"targeting_pass":"passb"}' },
             );
             
ok my $well_targ_pass = model->retrieve_well_targeting_pass({ id => $well_data->{id} }), 'retrieved new well targeting pass';

is $well_targ_pass->result, 'passb', 'well targeting pass updated to passb';

is $well_data->{'gf3'}, 'true', 'gf3 band is true';
$mech->put_ok('/api/well/genotyping_qc/'.$well_data->{id}.'?plate_name='.$plate,
             {'content-type' => 'application/json', 'content' => '{"gf3":"-"}' },
             );
throws_ok {
    model->retrieve_well_primer_bands({ id => $well_data->{id} });
} qr/No WellPrimerBands entity found matching/;

done_testing();
