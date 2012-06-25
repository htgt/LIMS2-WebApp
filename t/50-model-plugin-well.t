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

my $well_data= test_data( 'well.yaml' );
note( "Testing well creation" );

{
    ok my $well = model->create_well( $well_data->{well_create} ),
        'create_well should succeed';
    isa_ok $well, 'LIMS2::Model::Schema::Result::Well';
    is $well->created_by->name, 'test_user@example.org', 'well has correct created by user';
    is $well->name, 'B01', 'well has correct name';
    is $well->plate->name, 'PCS100', 'well belongs to correct plate';

    ok my $retrieve_well = model->retrieve_well( { id => $well->id } ),
        'retrieve_well by id should succeed';
    is $well->id, $retrieve_well->id, 'has correct id';

    #ok $well_process->delete, 'can delete well process';
    ok $well->delete, 'can delete well';
}


{
    note( "Testing well retrieve" );
    ok my $well = model->retrieve_well( $well_data->{well_retrieve} ),
        'retrieve_plate by name should succeed';
    isa_ok $well, 'LIMS2::Model::Schema::Result::Well';
    is $well->name, 'A01', 'retrieved correct well';
    is $well->plate->name, 'PCS100', '.. on correct plate';

    note( "Testing create well accepted override" );
    ok my $override = model->create_well_accepted_override( $well_data->{well_accepted_override_create} ),
        'create_well_accepted_override should succeed';
    isa_ok $override, 'LIMS2::Model::Schema::Result::WellAcceptedOverride';
    is $override->accepted, 0, 'override has correct value';
    is $override->well->id, $well->id, 'override belongs to correct well';

    note( "Testing update well accepted override" );
    ok my $updated_override =  model->update_well_accepted_override( $well_data->{well_accepted_override_update} ),
        'update_well_accepted_override should succeed';
    is $updated_override->accepted, 1, 'override has correct value';

    throws_ok {
        model->update_well_accepted_override( $well_data->{well_accepted_override_update_same} );
    } qr/Well already has accepted override with value TRUE/;

    ok $override->delete, 'can delete override';
}

done_testing();
