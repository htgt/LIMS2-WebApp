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
    use_ok('LIMS2::Model::Util::CreatePlate', qw( merge_plate_process_data ) );
}

note( "Plate Create - merge plate process data" );

{
    my $well_data = {
        well_name    => 'A01',
        parent_plate => 'MOHFAQ0001_A_2',
        parent_well  => 'A01',
        cassette     => 'test_cassette',
        backbone     => '',
        recombinase  => 'Cre'
    };

    my $plate_data = {
        backbone => 'test_backbone',
        cassette => 'wrong_cassette',
        process_type => '2w_gateway',
    };

    ok merge_plate_process_data( $well_data, $plate_data );

    is_deeply $well_data, {
        well_name    => 'A01',
        parent_plate => 'MOHFAQ0001_A_2',
        parent_well  => 'A01',
        cassette     => 'test_cassette',
        backbone     => 'test_backbone',
        process_type => '2w_gateway',
        recombinase  => ['Cre'],
    }, 'well_data array is as expected';

}

#TODO test create_plate_well
#TODO test find_parent_well_ids

done_testing();
