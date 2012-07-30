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

my $plate_data= test_data( 'plate.yaml' );
note( "Testing plate creation" );

{
    ok my $plate = model->create_plate( $plate_data->{plate_create} ),
        'create_plate should succeed';
    isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';
    is $plate->type_id, 'INT', 'plate is of correct type';
    is $plate->created_by->name, 'test_user@example.org', 'plate has correct created by user';

    ok my $plate_comments = $plate->plate_comments, 'can retrieve plate_comments';
    is $plate_comments->next->comment_text, 'this is a awesome test comment';

    ok my $retrieve_plate = model->retrieve_plate( { id => $plate->id } ),
        'retrieve_plate by id should succeed';
    is $plate->id, $retrieve_plate->id, 'has correct id';

    ok $plate_comments->delete, 'can delete plate comments';
    ok $plate->delete, 'can delete plate';
}

note( "Testing plate retrieve" );

{
    ok my $plate = model->retrieve_plate( $plate_data->{plate_retrieve} ),
        'retrieve_plate by name should succeed';
    isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';
    is $plate->name, 'PCS00075_A', 'retrieved correct plate';
}

done_testing();
