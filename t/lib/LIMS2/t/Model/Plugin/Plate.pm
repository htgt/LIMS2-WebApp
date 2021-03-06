package LIMS2::t::Model::Plugin::Plate;
use base qw(Test::Class);
use Test::Most;

use LIMS2::Test;
use Try::Tiny;
use DateTime;
use File::Temp ':seekable';

use strict;

## no critic

=head1 NAME

LIMS2/t/Model/Plugin/Plate.pm - test class for LIMS2::Model::Plugin::Plate

=head1 DESCRIPTION

Test module structured for running under Test::Class

=head1 METHODS

=cut

sub all_tests : Test(69) {

    my $plate_data = test_data('plate.yaml');
    note("Testing plate creation");

    {
        ok my $plate = model->create_plate( $plate_data->{plate_create} ),
            'create_plate should succeed';
        isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';
        is $plate->type_id, 'INT', 'plate is of correct type';
        is $plate->created_by->name, 'test_user@example.org', 'plate has correct created by user';

        ok my $plate_comments = $plate->plate_comments, 'can retrieve plate_comments';
        is $plate_comments->next->comment_text, 'this is an awesome test comment',
            '..first comment is expected';

        ok my $retrieve_plate = model->retrieve_plate( { id => $plate->id } ),
            'retrieve_plate by id should succeed';
        is $plate->id, $retrieve_plate->id, 'has correct id';
    }

    note("Testing plate retrieve");

    {
        ok my $plate = model->retrieve_plate( $plate_data->{plate_retrieve} ),
            'retrieve_plate by name should succeed';
        isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';
        is $plate->name, 'PCS00075_A', 'retrieved correct plate';

        # retrieve plate by barcode
        $plate->update( { barcode => 'ABC123456' } );

        ok my $plate2 = model->retrieve_plate( $plate_data->{plate_retrieve_barcode} ),
            'retrieve_plate by barcode should succeed';
        is $plate->id, $plate2->id, '.. and we have the correct plate';

        throws_ok {
            model->retrieve_plate( { barcode => 'ZXY1234' } )
        } qr/No Plate entity found matching:/, 'throws error when trying to retrieve non existant plate';

    }

    {

        throws_ok {
            model->create_plate( $plate_data->{plate_create_already_exists} );
        }
        qr/Plate PCS00075_A already exists/,
            'throws correct error when trying to create plate that already exists';

    }

    note("Testing plate create with wells");

    {
        ok my $plate = model->create_plate( $plate_data->{plate_create_wells} ),
            'create_plate should succeed';
        isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';

        ok my $wells = $plate->wells, 'can retrieve plate wells';
        ok my $well = $wells->find( { name => 'A01' } ), '..retrieve well A01';
        ok my $process = $well->output_processes->first, '..can getme: TEST_COPY_PLATE
	created_by:  output process';
        is $process->type_id, 'first_electroporation', 'process is correct type';
        ok my $input_well = $process->process_input_wells->first->well,
            'retrieve input well for process';
        is $input_well->plate->name, 'MOHFAQ0001_A_2', '..correct plate';
        is $input_well->name, 'A01', '..correct well';

    }

    note("Testing SEP type plate create with wells");

    {
        ok my $plate = model->create_plate( $plate_data->{sep_plate_create_wells} ),
            'create_plate should succeed';
        isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';

        ok my $wells = $plate->wells, 'can retrieve plate wells';
        ok my $well = $wells->find( { name => 'A01' } ), '..retrieve well A01';
        ok my $process = $well->output_processes->first, '..can get output process';
        is $process->type_id, 'second_electroporation', 'process is correct type';
        ok my $process_input_wells = $process->process_input_wells,
            'retrieve input well for process';
        is $process_input_wells->count, 2, 'we have 2 input wells for process';
    }

    note("Plate Assay Complete");

    {
        ok my $plate = model->set_plate_assay_complete( $plate_data->{plate_assay_complete} ),
            'create_plate should succeed';
        isa_ok $plate, 'LIMS2::Model::Schema::Result::Plate';

        ok my $wells = $plate->wells, 'can retrieve plate wells';
        ok my $well = $wells->find( { name => 'A05' } ), '..retrieve well A05';
        is $well->assay_complete, '2012-05-21T00:00:00', 'assay complete is correct';
    }

    note("Plate Create CSV Upload");

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
            cell_line    => 'oct4:puro iCre/iFlpO #11',
        };

        ok my $plate = model->create_plate_csv_upload( $plate_params, $test_file ),
            'called create_plate_csv_upload';
        is $plate->name,    'EPTEST', '...expected plate name';
        is $plate->type_id, 'EP',     '...expected plate type';
        ok my $wells = $plate->wells, '..plate has wells';
        is $wells->count, 2, '..there are 2 wells';

    }

    note("Plate Create CSV Upload - SEP plate");

    {
        my $test_file = File::Temp->new or die( 'Could not create temp test file ' . $! );
        $test_file->print( "well_name,xep_plate,xep_well,dna_plate,dna_well\n"
                . "A01,XEP0006,A01,MOHFAQ0001_A_2,H11\n" );
        $test_file->seek( 0, 0 );

        my $plate_params = {
            plate_name   => 'SEPTEST',
            species      => 'Mouse',
            plate_type   => 'SEP',
            process_type => 'second_electroporation',
            created_by   => 'test_user@example.org',
        };

        ok my $plate = model->create_plate_csv_upload( $plate_params, $test_file ),
            'called create_plate_csv_upload';
        is $plate->name,    'SEPTEST', '...expected plate name';
        is $plate->type_id, 'SEP',     '...expected plate type';
        ok my $wells = $plate->wells, '..plate has wells';
        is $wells->count, 1, '..there are 2 wells';

        lives_ok {
            model->delete_plate( { id => $plate->id } );
        }
        'can delete plate we just created';

    }

    note('Create Plate by Copy');

    {
        ok my $copy_plate = model->create_plate_by_copy( $plate_data->{create_plate_by_copy} ),
            'create_plate_by_copy should succeed';
        isa_ok $copy_plate, 'LIMS2::Model::Schema::Result::Plate';
        is $copy_plate->name,    'TEST_COPY_PLATE', '... copy plate name is correct';
        is $copy_plate->type_id, 'DNA',             '...expected plate type: DNA';
        ok my $plate_wells = $copy_plate->wells, '...plate has wells';
        is $plate_wells->count, 96, '...there are 96 wells';

    }

    note('List Plates');

    {
        ok my ( $plate_list, $pager )
            = model->list_plates( { species => 'Mouse', plate_type => 'FP' } ),
            'can list plates of type FP';
        isa_ok $pager, 'DBIx::Class::ResultSet::Pager';
        my @plate_names = map { $_->name } @{$plate_list};

        # AS28 - added extra FP plates from summaries tests
        is_deeply \@plate_names,
            [
            'FP4734', 'FP4637', '1007', '1006', '1005', '1004',
            '1003',   '1002',   '1001', 'FFP0001'
            ],
            '..and plate list is correct';

        ok my ( $plate_list2, $pager2 )
            = model->list_plates( { species => 'Mouse', plate_name => 'FFP' } ),
            'can list plates with name like FFP';
        my @plate_names2 = map { $_->name } @{$plate_list2};
        is_deeply \@plate_names2, ['FFP0001'], '..and plate list is correct';
    }

    note('Plate Rename');

    {
        throws_ok {
            model->rename_plate( { name => 'EPTEST' } );
        }
        'LIMS2::Exception::Validation', 'must specify a new plate name';

        throws_ok {
            model->rename_plate( { name => 'BLAH123', 'new_name' => 'FOO123' } );
        }
        'LIMS2::Exception::NotFound', 'can not rename a non existant plate';

        throws_ok {
            model->rename_plate( { name => 'EPTEST', 'new_name' => 'PCS00056_A' } );
        }
        qr/Plate PCS00056_A already exists/, 'can not rename a plate to a already existing name';

        ok my $plate = model->rename_plate( { name => 'EPTEST', new_name => 'EPRENAME' } ),
            'can rename plate';
        is $plate->name, 'EPRENAME', '..plate has correct name';

    }

    note("Testing delete_plate");

    {
        throws_ok {
            model->delete_plate( { name => 'PCS00056_A' } );
        }
        qr/Plate PCS00056_A can not be deleted, has child plates/,
            'throws error if trying to delete plate with child plates';
    }

    {

        lives_ok {
            model->delete_plate( { name => 'PCS101' } );
        }
        'delete plate';

        lives_ok {
            model->delete_plate( { name => 'EP10001' } );
        }
        'delete plate';

        lives_ok {
            model->delete_plate( { name => 'SEP10001' } );
        }
        'delete plate';

        lives_ok {
            model->delete_plate( { name => 'EPRENAME' } );
        }
        'delete plate';
    }

}

## use critic

1;

__END__

