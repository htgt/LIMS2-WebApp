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

sub a_test_create_well_expansion : Test(18) {
    my $plate = 'HUPEP0026';
    my $epplate = model->schema->resultset('Plate')->find( { name => $plate } );
    ok $epplate, "ep plate $epplate exists in database";
    ok create_well_expansion(model, {
            plate_name => 'HUPEP0026',
            parent_well => 'A01',
            child_well_number => 336,
            species => 'Human',
            created_by => 'beth', }), 'create_well_expansion returns True with arguments';
    my @child_plates = qw(0026D1 0026A1 0026B1 0026C1);
    my $expected_well_number = 48;
    foreach my $child_plate (@child_plates) {
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
                 [ map { { id => $epplate->id, name => 'A01' } } 1 .. $expected_well_number ];
        my @epd_wells = $epd_plate->wells;
        $DB::single=1;
        is_deeply [ map { { id => $_->plate_id, name => $_->name } } @fp_input_wells ],
                    [ map { { id => $_->plate_id, name => $_->name } } @epd_wells ];
        $expected_well_number = 96;
   }
}
## use critic

1;

__END__
