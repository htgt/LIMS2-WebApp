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
use File::Temp ':seekable';

my $plate_data= test_data( 'plate.yaml' );
note( "Testing plate creation" );

{
    ok my $plate = model->create_plate( $plate_data->{plate_create} ),
        'create_plate should succeed';
    isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';
    is $plate->type_id, 'INT', 'plate is of correct type';
    is $plate->created_by->name, 'test_user@example.org', 'plate has correct created by user';

    ok my $plate_comments = $plate->plate_comments, 'can retrieve plate_comments';
    is $plate_comments->next->comment_text, 'this is a awesome test comment', '..first comment is expected';

    ok my $retrieve_plate = model->retrieve_plate( { id => $plate->id } ),
        'retrieve_plate by id should succeed';
    is $plate->id, $retrieve_plate->id, 'has correct id';
}

note( "Testing plate retrieve" );

{
    ok my $plate = model->retrieve_plate( $plate_data->{plate_retrieve} ),
        'retrieve_plate by name should succeed';
    isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';
    is $plate->name, 'PCS00075_A', 'retrieved correct plate';
}

note( "Testing plate create with wells" );

{
    ok my $plate = model->create_plate( $plate_data->{plate_create_wells} ),
        'create_plate should succeed';
    isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';

    ok my $wells = $plate->wells, 'can retrieve plate wells';
    ok my $well = $wells->find( { name => 'A01' } ), '..retrieve well A01';
    ok my $process = $well->output_processes->first, '..can get output process';
    is $process->type_id, 'first_electroporation', 'process is correct type';
    ok my $input_well = $process->process_input_wells->first->well, 'retrieve input well for process';
    is $input_well->plate->name, 'MOHFAQ0001_A_2', '..correct plate';
    is $input_well->name, 'A01', '..correct well';

}

note( "Testing SEP type plate create with wells" );

{
    ok my $plate = model->create_plate( $plate_data->{sep_plate_create_wells} ),
        'create_plate should succeed';
    isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';

    ok my $wells = $plate->wells, 'can retrieve plate wells';
    ok my $well = $wells->find( { name => 'A01' } ), '..retrieve well A01';
    ok my $process = $well->output_processes->first, '..can get output process';
    is $process->type_id, 'second_electroporation', 'process is correct type';
    ok my $process_input_wells = $process->process_input_wells, 'retrieve input well for process';
    is $process_input_wells->count, 2, 'we have 2 input wells for process';
}

note( "Plate Assay Complete" );

{
    ok my $plate = model->set_plate_assay_complete( $plate_data->{plate_assay_complete} ),
        'create_plate should succeed';
    isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';

    ok my $wells = $plate->wells, 'can retrieve plate wells';
    ok my $well = $wells->find( { name => 'A05' } ), '..retrieve well A05';
    is $well->assay_complete,'2012-05-21T00:00:00', 'assay complete is correct';
}


note( "Plate Create CSV Upload" );

{
    my $test_file = File::Temp->new or die( 'Could not create temp test file ' . $! );
    $test_file->print( "well_name,parent_plate,parent_well,cell_line\n"
            . "A01,MOHFAQ0001_A_2,A01\n"
            . "A02,MOHFAQ0001_A_2,A02\n" );
    $test_file->seek( 0, 0 );

    my $plate_params = {
        plate_name   => 'EPTEST',
        species      => 'Mouse',
        plate_type   => 'EP',
        process_type => 'first_electroporation',
        created_by   => 'test_user@example.org',
        cell_line    => 'cell_line_bar',
    };

    ok my $plate = model->create_plate_csv_upload( $plate_params, $test_file ),
        'called create_plate_csv_upload';
    is $plate->name,    'EPTEST', '...expected plate name';
    is $plate->type_id, 'EP',     '...expected plate type';
    ok my $wells = $plate->wells, '..plate has wells';
    is $wells->count, 2, '..there are 2 wells';

}

{
    note( "Testing delete_plate" );

    lives_ok {
        model->delete_plate( { name => 'PCS101' } )
    } 'delete plate';

    lives_ok {
        model->delete_plate( { name => 'EP10001' } )
    } 'delete plate';

    lives_ok {
        model->delete_plate( { name => 'SEP10001' } )
    } 'delete plate';

    lives_ok {
        model->delete_plate( { name => 'EPTEST' } )
    } 'delete plate';
}

#TODO add tests for set_plate_assay_complete
done_testing();
