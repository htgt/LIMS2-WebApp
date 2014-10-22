package LIMS2::t::Model::Util::BarcodeActions;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::BarcodeActions qw/
            discard_well_barcode
            freeze_back_barcode
            add_barcodes_to_wells
    /;

use LIMS2::Test model => { classname => __PACKAGE__ };

sub discard_tests : Tests(13){

    my $bc = '7';
    my $unchanged_well = 'A02';

    # Fetch the barcode and one other well from the same plate
    ok my $well_bc = model->retrieve_well_barcode({ barcode => $bc }), "Barcode $bc found";
    my $well_name = $well_bc->well->name;
    is scalar($well_bc->well->plate->wells), 49, "Original plate has 49 of wells";
    ok my $orig_a2 = $well_bc->well->plate->search_related('wells',{ name => $unchanged_well })->first, "$unchanged_well found";

    # Check well gets discarded from new version of plate
    ok my $new_plate = discard_well_barcode(model,{
	    barcode => $bc,
	    user    => 'test_user@example.org',
	    reason  => 'testing',
	}), "Barcode discarded";
	is scalar($new_plate->wells), 48, "New plate version has 48 wells";
    is $new_plate->version, undef, "New plate has no version number";
	my $discarded_well = $new_plate->search_related('wells',{ name => $well_name })->first;
	is $discarded_well, undef, "$well_name is not on new plate";

    # Check orig plate has been updated
	ok $well_bc = model->retrieve_well_barcode({ barcode => $bc }), "Barcode $bc found";
	is $well_bc->barcode_state->id, "discarded", "Well status updated";
    is scalar($well_bc->well->plate->wells), 49, "Original plate still has 49 wells";
    is $well_bc->well->plate->version, 1, "Original plate has version number 1";

    # Check well from orig plate is parent of same well on the new plate
    ok my $new_a2 = $new_plate->search_related('wells',{ name => $unchanged_well })->first, "New $unchanged_well found";
    my ($parent) = $new_a2->parent_wells;
    is $parent->id, $orig_a2->id, "Orig $unchanged_well is parent of new $unchanged_well";

}

sub freeze_back_tests : Tests(18){
	my $bc = 10;
	my $unchanged_well = 'B01';

    my $params = {
        barcode => $bc,
        number_of_wells => 3,
        lab_number => 'TEST',
        qc_piq_plate_name => 'QC_TEST',
        qc_piq_well_name => 'A01',
        user => 'test_user@example.org',
    };

    $params->{barcode} = 11;
    throws_ok( sub { freeze_back_barcode(model,$params) },
    	       qr/not checked_out/,
    	       "cannot freeze back without checkout");

    $params->{barcode} = $bc;

    # Fetch the barcode and one other well from the same plate
    ok my $well_bc = model->retrieve_well_barcode({ barcode => $bc }), "Barcode $bc found";
    my $well_name = $well_bc->well->name;
    my $plate_name = $well_bc->well->plate->name;
    is scalar($well_bc->well->plate->wells), 48, "Original plate has 48 wells";
    ok my $orig_unchanged = $well_bc->well->plate->search_related('wells',{ name => $unchanged_well })->first, "$unchanged_well found";

    # Do the freeze back and check everything is created as expected
    ok my $tmp_piq_plate = freeze_back_barcode(model, $params), "barcode $bc frozen back";

    is scalar($tmp_piq_plate->wells), $params->{number_of_wells}, "Correct number of child PIQ wells on tmp plate";
    my ($tmp_well) = $tmp_piq_plate->wells;
    like $tmp_well->well_lab_number->lab_number, qr/$params->{lab_number}/, "Child PIQ well lab number correct";

    my ($qc_well) = $tmp_well->parent_wells;
    is $qc_well->name, $params->{qc_piq_well_name}, "QC PIQ well name correct";
    is $qc_well->plate->name, $params->{qc_piq_plate_name}, "QC PIQ plate name correct";
    is $qc_well->well_lab_number->lab_number, $params->{lab_number}, "QC PIQ lab number correct";

    my ($qc_parent) = $qc_well->parent_wells;
    is $qc_parent->name, $well_name, "QC well parented by correct well";
    like $qc_parent->plate->name, qr/$plate_name/, "QC well parented by correct plate";

    # Check orig plate has been updated
	ok $well_bc = model->retrieve_well_barcode({ barcode => $bc }), "Barcode $bc found";
	is $well_bc->barcode_state->id, "frozen_back", "Well status updated";
    is scalar($well_bc->well->plate->wells), 48, "Original plate still has 48 wells";

    # Check unchanged well still exists on new version of FP plate
    ok my $new_plate = model->retrieve_plate({ name => $plate_name }), "New FP plate found";
    ok my $new_unchanged = $new_plate->search_related('wells',{ name => $unchanged_well })->first, "New $unchanged_well found";
    my ($parent) = $new_unchanged->parent_wells;
    is $parent->id, $orig_unchanged->id, "Orig $unchanged_well is parent of new $unchanged_well";
}
1;
