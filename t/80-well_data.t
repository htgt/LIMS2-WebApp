#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';

BEGIN {
    use Log::Log4perl qw( :easy );
    Log::Log4perl->easy_init( $FATAL );
}

my $mech = mech();

{
    note( "set no data" );
    $mech->get_ok( '/user/update_colony_picks_step_1' );
    $mech->title_is('Colony Counts');
    ok my $res = $mech->submit_form(
        form_id => 'colony_count_form',
        fields  => { plate_name => '', well_name => ''},
    ), 'submit form with no data selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/update_colony_picks_step_1', '...stays on the same page';
    like $res->content, qr/id_or_name, is missing/, '... no data specified';
}

{
    note( "select invalid plate type" );
    $mech->get_ok( '/user/update_colony_picks_step_1' );
    $mech->title_is('Colony Counts');
    ok my $res = $mech->submit_form(
        form_id => 'colony_count_form',
        fields  => { plate_name => 'FEPD0006_1', well_name => 'A01'},
    ), 'submit form with no data selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/update_colony_picks_step_1', '...stays on the same page';
    like $res->content, qr/invalid plate type; can only add colony data to EP, SEP and XEP plates/, '... invalid plate type';
}

{
    note( "set valid plate type" );
    $mech->get_ok( '/user/update_colony_picks_step_1' );
    $mech->title_is('Colony Counts');
    ok my $res = $mech->submit_form(
        form_id => 'colony_count_form',
        fields  => { plate_name => 'FEP0006', well_name => 'A01'},
    ), 'submit form with no data selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/update_colony_picks_step_2', '...move to step 2';
    like $res->content, qr/total_colonies/, '... valid plate type';
}

{
    note( "set valid plate type" );
    $mech->get_ok( '/user/update_colony_picks_step_2' );
    $mech->title_is('Colony Counts');
    ok my $res = $mech->submit_form(
        form_id => 'colony_count_form',
        fields  => { plate_name => 'FEP0006', well_name => 'A01', total_colonies => 30},
    ), 'submit form with no data selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/update_colony_picks_step_1', '...move to step 1';
    like $res->content, qr/Successfully added colony picks/, '... valid plate type';
}

{
    note( "Invalid colony count data csv file" );

    $mech->get_ok( '/user/update_colony_picks_step_1' );
    $mech->title_is('Colony Counts');
    ok my $res = $mech->submit_form(
        form_id => 'colony_count_upload',
        fields  => {
            datafile   => ''
        },
        button  => 'upload'
    ), 'submit form with invalid colony count data csv file';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/update_colony_picks_step_1', '... stays on same page';
    like $res->content, qr/No csv file with well colony counts data specified/
        , '...throws error invalid colony count data csv file';
}

done_testing;
