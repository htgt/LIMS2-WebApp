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
    is $well->name, 'A01', 'well has correct name';
    is $well->plate->name, 'PCS00177_A', 'well belongs to correct plate';

    ok my $retrieve_well = model->retrieve_well( { id => $well->id } ),
        'retrieve_well by id should succeed';
    is $well->id, $retrieve_well->id, 'has correct id';
}

{
    note( "Testing well retrieve" );
    ok my $well = model->retrieve_well( $well_data->{well_retrieve} ),
        'retrieve_plate by name should succeed';
    isa_ok $well, 'LIMS2::Model::Schema::Result::Well';
    is $well->name, 'A01', 'retrieved correct well';
    is $well->plate->name, 'PCS00177_A', '.. on correct plate';

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

{
    note( "Testing set_well_assay_complete" );

    my $date_time = DateTime->new(
        year   => 2010,
        month  => 9,
        day    => 12,
        hour   => 10,
        minute => 5,
        second => 7
    );

    my %params = ( %{ $well_data->{well_retrieve} },
                   completed_at => $date_time->iso8601
               );

    ok my $well = model->set_well_assay_complete( \%params ), 'set_well_assay_complete should succeed';

    ok ! $well->accepted, 'well is not automatically accepted';

    is $well->assay_complete, $date_time, 'assay_complete has expected datetime';

    ok model->create_well_qc_sequencing_result(
        {
            well_id         => $well->id,
            valid_primers   => 'LR,PNF,R1R',
            pass            => 1,
            test_result_url => 'http://example.org/some/url/or/other',
            created_by      => 'test_user@example.org'
        }
    ), 'create QC sequencing result';

    $date_time = DateTime->now;

    ok $well = model->set_well_assay_complete( { id => $well->id, completed_at => $date_time->iso8601 } ),
        'set_well_assay_complete should succeed';

    ok $well->accepted, 'well is automatically accepted now that we have a sequencing pass';

    is $well->assay_complete, $date_time, 'assay_complete has expected datetime';
}

{
    note( "Testing delete_well" );

    lives_ok {
        model->delete_well( { plate_name => 'PCS00177_A', well_name => 'A01' } )
    } 'delete well';
}

done_testing();
