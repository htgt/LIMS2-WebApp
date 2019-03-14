package LIMS2::t::Model::Util::EPPipelineIIWellExpansion;

use LIMS2::Model::Util::EPPipelineIIWellExpansion;

use strict;
use warnings;

use base qw( Test::Class );
use Test::Most;

use LIMS2::Model::Util::EPPipelineIIWellExpansion qw/
    create_well_expansion
    /;
use LIMS2::Test model => { classname => __PACKAGE__ };

## no critic

sub a_test_create_well_expansion : Test(19) {
    my $plate = 'HUPEP0026';
    my $epplate = model->schema->resultset('Plate')->find( { name => $plate } );
    ok $epplate, "ep plate $epplate exists in database";
    my $epd_params = {
        name => 'HUPEPD0026A1',
        species => 'Human',
        type => 'EP_PICK',
        created_by => 'beth',
    };
    my $fp_params = {
        name => 'HUPFP0026A1',
        species => 'Human',
        type => 'FP',
        created_by => 'beth',
    };
    model->create_plate($epd_params);
    model->create_plate($fp_params);
    create_well_expansion(model, {
            plate_name => $plate,
            parent_well => 'A01',
            child_well_number => 240,
            species => 'Human',
            created_by => 'beth', });
    my @expected_child_plates = qw(0026D1 0026C1 0026B1);
    my $expected_well_number = 48;
    foreach my $child_plate (@expected_child_plates) {
        ok my $epd_plate = model->schema->resultset('Plate')->find( { name => "HUPEPD$child_plate" } ),
            "plate HUPEPD$child_plate exists in database";
        ok my $freeze_plate = model->schema->resultset('Plate')->find( { name => "HUPFP$child_plate" } ),
            "plate HUPFP$child_plate exists in database";
        my @epd_input_wells = map {$_->input_wells}
                        map {$_->parent_processes}
                        $epd_plate->wells;
        my @fp_input_wells = map {$_->input_wells}
                        map {$_->parent_processes}
                        $freeze_plate->wells;
        is_deeply [ map { { id => $_->plate_id, name => $_->name, } } @epd_input_wells ],
                 [ map { { id => $epplate->id, name => 'A01' } } 1 .. $expected_well_number ], 'correct epd wells parents';
        my @epd_wells = $epd_plate->wells;
        is_deeply [ map { { id => $_->plate_id, name => $_->name } } @fp_input_wells ],
                    [ map { { id => $_->plate_id, name => $_->name } } @epd_wells ], 'correct fp wells parents';
        $expected_well_number = 96;
   }
    return;
}
## use critic

1;

__END__
