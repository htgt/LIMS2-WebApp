#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';

my $mech = unauthenticated_mech();

$mech->get_ok( '/login' );
ok $mech->submit_form(
    form_name => 'login_form',
    fields    => { username => 'test_user@example.org', password => 'ahdooS1e' },
    button    => 'login'
), 'Login with correct username and password';

{
    note( "No well data file set" );
    $mech->get_ok( '/user/dna_status_update' );
    $mech->title_is('DNA Status Update');
    ok my $res = $mech->submit_form(
        form_id => 'dna_status_update',
        fields  => {
            plate_name => 'MOHFAQ0001_A_2',
        },
        button  => 'update_dna_status'
    ), 'submit form without file';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/dna_status_update', '... stays on same page';
    like $res->content, qr/No csv file with dna status data specified/, '...throws error saying no csv file specified';
}

{
    note( "No plate_name set" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print('Test File');

    $mech->get_ok( '/user/dna_status_update' );
    $mech->title_is('DNA Status Update');
    ok my $res = $mech->submit_form(
        form_id => 'dna_status_update',
        fields  => {
            datafile   => $test_file->filename
        },
        button  => 'update_dna_status'
    ), 'submit form without plate name';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/dna_status_update', '... stays on same page';
    like $res->content, qr/You must specify a plate name/, '...throws error must specify plate name';
}

{
    note( "Invalid csv data" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,pass\n"
                      . "BLAH,pass");
    $test_file->seek( 0, 0 );

    $mech->get_ok( '/user/dna_status_update' );
    $mech->title_is('DNA Status Update');
    ok my $res = $mech->submit_form(
        form_id => 'dna_status_update',
        fields  => {
            plate_name => 'MOHFAQ0001_A_2',
            datafile   => $test_file->filename
        },
        button  => 'update_dna_status'
    ), 'submit form with well data file with invalid well data';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/dna_status_update', '... stays on same page';
    like $res->content, qr/Parameter validation failed\s+well_name/
        , '...throws error parameter validation failed for well_name';
}

{
    note( "Successful creation of dna status values" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,pass,comments\n"
                      . "D02,pass,this is a comment");
    $test_file->seek( 0, 0 );

    $mech->get_ok( '/user/dna_status_update' );
    $mech->title_is('DNA Status Update');
    ok my $res = $mech->submit_form(
        form_id => 'dna_status_update',
        fields  => {
            plate_name => 'MOHFAQ0001_A_2',
            datafile   => $test_file->filename
        },
        button  => 'update_dna_status'
    ), 'submit form with valid parameters';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/dna_status_update', '... stays on same page';
    like $res->content, qr/Uploaded dna status information onto plate MOHFAQ0001_A_2/ ,
        '...page has success message';

    my $dna_status;
    lives_ok {
        $dna_status = model->retrieve_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'D02' } );
    } 'retrieve newly created dna status';
    is $dna_status->pass, 1, 'has correct pass value';
    is $dna_status->comment_text, 'this is a comment', 'has correct comment';
}

{
    note( "Delete newly created dna status" );

    lives_ok {
        model->delete_well_dna_status( { plate_name => 'MOHFAQ0001_A_2', well_name => 'D02' } )
    } 'delete dna status data';
}

done_testing;
