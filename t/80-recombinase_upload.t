#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Test;
use Test::Most;
use File::Temp ':seekable';

my $mech = mech();

{
    note( "set no data" );
    $mech->get_ok( '/user/recombinase_upload' );
    $mech->title_is('Add Recombinase');
    ok my $res = $mech->submit_form(
        form_id => 'recombinase_form',
        fields  => { plate_name => '', well_name => '', recombinase => ''},
    ), 'submit form with no data selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/recombinase_upload', '...stays on the same page';
    like $res->content, qr/Data must be specified for all three fields; Plate Name, Well Name and Recombinase/, '... no data specified';
}

{
    note( "set valid data" );
    $mech->get_ok( '/user/recombinase_upload' );
    $mech->title_is('Add Recombinase');
    ok my $res = $mech->submit_form(
        form_id => 'recombinase_form',
        fields  => { plate_name => 'FEPD0006_1', well_name => 'A01', recombinase => 'Dre'},
    ), 'submit form with no data selected';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/recombinase_upload', '...stays on the same page';
    like $res->content, qr/Add Dre recombinase for well A01 on plate FEPD0006_1/, '... no data specified';
}

{
    note( "Invalid well data csv file" );

    $mech->get_ok( '/user/recombinase_upload' );
    $mech->title_is('Add Recombinase');
    ok my $res = $mech->submit_form(
        form_id => 'recombinase_file_upload',
        fields  => {
            datafile   => ''
        },
        button  => 'upload'
    ), 'submit form with invalid well data csv file';

    ok $res->is_success, '...response is_success';
    is $res->base->path, '/user/recombinase_upload', '... stays on same page';
    like $res->content, qr/No csv file with recombinase data specified/
        , '...throws error invalid recombinase data csv file';
}

done_testing;
