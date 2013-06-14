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
use Data::Dumper;
use YAML::Any qw(DumpFile);
use Hash::MoreUtils qw( slice_def );

my $well_data= test_data( 'well.yaml' );

{
    note("Testing well lab number create, retrieve and delete");

    ok my $piq_plate = model->create_plate( $well_data->{piq_plate_create}), 'create PIQ plate should succeed';

    ok my $piq_well = model->create_well( $well_data->{piq_well_create_one} ), 'create PIQ well should succeed';

    throws_ok {
        model->create_well_lab_number( { well_id => $piq_well->id, }  );
    } qr/Parameter validation failed/;

    ok model->create_well_lab_number( { well_id => $piq_well->id, lab_number => 'LAB 001', }  )
    , 'lab_number created successfully' ;

    throws_ok {
        model->create_well_lab_number( { well_id => $piq_well->id, lab_number => 'LAB 001', }  );
    } qr/Well PIQTEST001_A01 already has a Lab Number, with a value of LAB 001/;

    ok my $lab_number = model->retrieve_well_lab_number( { plate_name =>'PIQTEST001', well_name => 'A01' } ), 'can retrieve Lab Number data for well';

    is $lab_number->lab_number, 'LAB 001', 'Lab Number retrieved is correct';

    ok my $well = $lab_number->well, '.. can grab well from lab_number';
    
    is "$well", 'PIQTEST001_A01', '.. and lab_number is for right well';

    ok $lab_number = model->update_or_create_well_lab_number( {  well_id => $piq_well->id , lab_number => 'LAB 002' } ), 'can update Lab Number when new Lab Number is unique';

    is $lab_number->lab_number, 'LAB 002', '..updated result is now LAB 002';

    throws_ok {
    	$lab_number = model->update_or_create_well_lab_number( {  well_id => $piq_well->id , lab_number => 'LAB 002' } );
    } qr/Update unnecessary. Lab Number LAB 002 is unchanged/;

    lives_ok {
        model->delete_well_lab_number( { plate_name =>'PIQTEST001', well_name => 'A01' } )
    } 'delete well lab number should succeed';

    throws_ok {
        model->retrieve_well_lab_number( { plate_name =>'PIQTEST001', well_name => 'A01' } )
    } qr/No WellLabNumber entity should be found/;

    ok $lab_number = model->update_or_create_well_lab_number( {  well_id => $piq_well->id , lab_number => 'LAB 003' } ), 'can create Lab Number when none exists for well';

    is $lab_number->lab_number, 'LAB 003', '..updated result is now LAB 003';

    ok my $piq_well_two = model->create_well( $well_data->{piq_well_create_two} ), 'creating a second PIQ well should succeed';

    throws_ok {
    	my $lab_number_two = model->update_or_create_well_lab_number( {  well_id => $piq_well_two->id , lab_number => 'LAB 003' } );
    } qr/Create failed. Lab Number LAB 003 has already been used in well PIQTEST001_A01/;
}

done_testing();