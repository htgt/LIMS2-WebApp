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
    note( "set undef process type" );
    $mech->get_ok( '/user/plate_upload_step1' );
    $mech->title_is('Plate Upload');
    ok my $res = $mech->submit_form(
        form_id => 'process_type_select',
        fields  => { process_type => ''},
    ), 'submit form with no process type selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step1', '...stays on the same page';
    like $res->content, qr/You must specify a process type/, '... no process type specified';
}

{
    note( "set invalid process type" );
    $mech->get_ok( '/user/plate_upload_step1' );
    $mech->title_is('Plate Upload');
    ok my $res = $mech->submit_form(
        form_id => 'process_type_select',
        fields  => { process_type => 'foo'},
    ), 'submit form with invalid process type selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... moves onto step 2';
    like $res->content, qr/is invalid: existing_process_type/, '...correct validation error';
}

{
    note( "set process type to rearray" );
    $mech->get_ok( '/user/plate_upload_step1' );
    $mech->title_is('Plate Upload');
    ok my $res = $mech->submit_form(
        form_id => 'process_type_select',
        fields  => { process_type => 'rearray'},
    ), 'submit form with rearray process type selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... moves onto step 2';
    like $res->content, qr/rearray/, '...process type set to rearray';
}

{
    note( "set process type to first_electroporation" );
    $mech->get_ok( '/user/plate_upload_step1' );
    $mech->title_is('Plate Upload');
    ok my $res = $mech->submit_form(
        form_id => 'process_type_select',
        fields  => { process_type => 'first_electroporation'},
    ), 'submit form with first_electroporation process type selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... moves onto step 2';
    like $res->content, qr/first_electroporation/, '...process type set to first_electroporation';
    like $res->content, qr/Cell Line/, '...has cell_line field';
}

{
    note( "2w_gateway process type form check" );
    $mech->get_ok( '/user/plate_upload_step2?process_type=2w_gateway' );
    $mech->title_is('Plate Upload 2');
    $mech->text_contains('Backbone (Final)', '...have Backbone field');
    $mech->text_contains('Cassette (Final)', '...have Cassette field');

}

{
    note( "No well data file set" );
    $mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
    $mech->title_is('Plate Upload 2');
    $mech->text_contains('Cell Line', '...have Cell Line field');
    ok my $res = $mech->submit_form(
        form_id => 'plate_create',
        fields  => {
            plate_name   => 'EPTEST',
            process_type => 'first_electroporation',
            plate_type   => 'EP',
        },
        button  => 'create_plate'
    ), 'submit form without file';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
    like $res->content, qr/No csv file with well data specified/, '...throws error saying no csv file specified';
}

{
    note( "No plate_name set" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print('Test File');

    $mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
    $mech->title_is('Plate Upload 2');
    $mech->text_contains('Cell Line', '...have Cell Line field');
    ok my $res = $mech->submit_form(
        form_id => 'plate_create',
        fields  => {
            plate_type => 'EP',
            datafile   => $test_file->filename
        },
        button  => 'create_plate'
    ), 'submit form without plate name';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
    like $res->content, qr/Must specify a plate name/, '...throws error must specify plate name';
}

{
    note( "No plate_type set" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print('Test File');

    $mech->get_ok( '/user/plate_upload_step2?process_type=rearray' );
    $mech->title_is('Plate Upload 2');
    ok my $res = $mech->submit_form(
        form_id => 'plate_create',
        fields  => {
            plate_name => 'TEST',
            datafile   => $test_file->filename
        },
        button  => 'create_plate'
    ), 'submit form without plate type';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
    like $res->content, qr/Must specify a plate type/, '...throws error must specify plate type';
}

{
    note( "Invalid well data csv file" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);

    $mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
    $mech->title_is('Plate Upload 2');
    ok my $res = $mech->submit_form(
        form_id => 'plate_create',
        fields  => {
            plate_name => 'EPTEST',
            datafile   => $test_file->filename
        },
        button  => 'create_plate'
    ), 'submit form with invalid well data csv file';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
    like $res->content, qr/Error encountered while creating plate: Invalid csv file/
        , '...throws error invalid well data csv file';
}

{
    note( "No well data" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print('Test File');
    $test_file->seek( 0, 0 );
    #my $test_file_content = "well_name,parent_plate,parent_well\n" . "A01,MOHFAQ001_A_2,A01";

    $mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
    $mech->title_is('Plate Upload 2');
    ok my $res = $mech->submit_form(
        form_id => 'plate_create',
        fields  => {
            plate_name => 'EPTEST',
            datafile   => $test_file->filename
        },
        button  => 'create_plate'
    ), 'submit form with well data file with no well data';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
    like $res->content, qr/Error encountered while creating plate: No data in csv file/
        , '...throws error no well data in file';
}

{
    note( "Invalid well data" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,parent_plate,parent_well,cell_line\n" 
                      . "BLAH,MOHFAQ001_A_2,A01,cell_line_foo");
    $test_file->seek( 0, 0 );

    $mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
    $mech->title_is('Plate Upload 2');
    ok my $res = $mech->submit_form(
        form_id => 'plate_create',
        fields  => {
            plate_name => 'EPTEST',
            datafile   => $test_file->filename
        },
        button  => 'create_plate'
    ), 'submit form with well data file with invalid well data';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/plate_upload_step2', '... stays on same page';
    like $res->content, qr/Parameter validation failed\s+well_name/
        , '...throws error parameter validation failed for well_name';
}

{
    note( "Successful plate create" );
    my $test_file = File::Temp->new or die('Could not create temp test file ' . $!);
    $test_file->print("well_name,parent_plate,parent_well,cell_line\n" 
                      . "A01,MOHFAQ0001_A_2,A01,cell_line_foo");
    $test_file->seek( 0, 0 );

    $mech->get_ok( '/user/plate_upload_step2?process_type=first_electroporation' );
    $mech->title_is('Plate Upload 2');
    ok my $res = $mech->submit_form(
        form_id => 'plate_create',
        fields  => {
            plate_name => 'EPTEST',
            datafile   => $test_file->filename
        },
        button  => 'create_plate'
    ), 'submit form with valid well data file';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/view_plate', '... moves to plate view page';
    like $res->content, qr/Created new plate EPTEST/ , '...page has create new plate message';
}

{
    note( "Delete newly created plate" );

    lives_ok {
        model->delete_plate( { name => 'EPTEST' } )
    } 'delete plate';
}

done_testing;
