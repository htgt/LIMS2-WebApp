#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;

my $mech = mech();

my $plate_without_children = model->retrieve_plate( { name => 'FFP0001' } );
my $plate_with_children = model->retrieve_plate( { name => 'PCS00097_A' } );

{
    note( "Visit plate edit page" );

    $mech->get_ok( '/user/view_plate?id=' . $plate_without_children->id );
    $mech->title_is('View Plate');
    $mech->content_like( qr/delete_plate_button/, '..has delete plate button');

    $mech->get_ok( '/user/view_plate?id=' . $plate_with_children->id );
    $mech->title_is('View Plate');
    $mech->content_unlike( qr/delete_plate_button/, '..has no delete plate button');
}

{
    note( "Test rename plate" );
    my $plate = model->retrieve_plate( { name => 'SEP0006' } );

    $mech->get_ok( '/user/rename_plate?id=' . $plate->id . '&name=' . $plate->name . '&new_name=' . $plate_with_children->name );
    $mech->base_like( qr{user/view_plate},'...moves to view_plates page');
    $mech->content_like( qr/Error encountered while renaming plate: .* already exists/, '...correct plate rename error message');

    $mech->get_ok( '/user/rename_plate?id=' . $plate->id . '&name=' . $plate->name . '&new_name=FOOBAR' );
    $mech->base_like( qr{user/view_plate},'...moves to view_plate page');
    $mech->content_like( qr/Renamed plate from SEP0006 to FOOBAR/, '...correct plate rename message');
}

{
    note( "Test plate delete" );

    $mech->get_ok( '/user/delete_plate?id=' . $plate_without_children->id . '&name=' . $plate_without_children->name );
    $mech->base_like( qr{user/browse_plates},'...moves to browse_plates page');
    $mech->content_like( qr/Deleted plate FFP0001/, '...correct plate delete message');

    $mech->get_ok( '/user/delete_plate?id=' . $plate_with_children->id . '&name=' . $plate_with_children->name );
    $mech->base_like( qr{user/view_plate},'...moves to view_plate page');
    $mech->content_like( qr/Error encountered while deleting plate: .* has child plates/, '...correct delete plate error message');
}


done_testing;
