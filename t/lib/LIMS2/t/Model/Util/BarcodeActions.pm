package LIMS2::t::Model::Util::BarcodeActions;
use strict;
use warnings FATAL => 'all';

use base qw( Test::Class );
use Test::Most;
use LIMS2::Model::Util::BarcodeActions qw/
            discard_well_barcode
            freeze_back_barcode
            add_barcodes_to_wells
            checkout_well_barcode
            upload_plate_scan
            send_out_well_barcode
    /;
use File::Temp qw/ tempfile /;
use LIMS2::Test model => { classname => __PACKAGE__ };


sub csv_add_barcodes : Tests(){
    my $well_name = 'A11';
    my $plate_name = 'FP4637';
    my $well = model->retrieve_well({ well_name => $well_name, plate_name => $plate_name});
    is $well->well_barcode,undef, "Well has no barcode";

    my $fh = tempfile();
    my $bc = "test1";
    print $fh "$well_name,$bc";
    $fh->seek(0,0);

    ok my ($plate, $messages) = upload_plate_scan(model,{
        existing_plate_name => $plate_name,
        species => 'Mouse',
        user => 'test_user@example.org',
        csv_fh => $fh,
    }), "Barcodes added to existing plate from csv upload";

    $well->discard_changes();
    is $well->well_barcode->barcode, $bc, 'Correct barcode has been added to well';

    $well->delete_related('well_barcode');
    $well->discard_changes();

    is $well->well_barcode,undef, "Well has no barcode";

    $fh = tempfile();
    print $fh "$well_name,$bc\nA02,extra_barcode\n";
    $fh->seek(0,0);

    ok my ($plate2, $messages2) = upload_plate_scan(model,{
        existing_plate_name => $plate_name,
        species => 'Mouse',
        user => 'test_user@example.org',
        csv_fh => $fh,
    }), "Barcodes added to existing plate from csv upload with extra empty well barcode";
    $well->discard_changes();
    is $well->well_barcode->barcode, $bc, 'Correct barcode has been added to well';
    is $messages2->[1]->{message}, 'A barcode <extra_barcode> has been scanned for a location where no tube was present, ignoring.',
        'Message indicates extra barcode was ignored';

    $fh->seek(0,0);
    ok my ($plate3, $messages3) = upload_plate_scan(model,{
        existing_plate_name => $plate_name,
        species => 'Mouse',
        user => 'test_user@example.org',
        csv_fh => $fh,
    }), "Plate scan csv matching existing plate uploaded without error";
    $well->discard_changes();
    is $well->well_barcode->barcode, $bc, 'Correct barcode has still linked to well';
    is $messages3->[1]->{message}, 'Uploaded barcodes match existing plate. No changes made.',
        'Message indicates upload is identical to plate';

}

sub discard_tests : Tests(13){

    my $bc = '7';
    my $unchanged_well = 'A02';

    # Fetch the barcode and one other well from the same plate
    ok my $well_bc = model->retrieve_well_barcode({ barcode => $bc }), "Barcode $bc found";
    my $well_name = $well_bc->well->name;
    is scalar($well_bc->well->plate->wells), 49, "Original plate has 49 wells";
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

sub freeze_back_tests : Tests(37){
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

    # Add barcodes to new wells on temp piq plate
    # Input params come from form like: <input type="text" name="barcode_[% well.id %]">
    my %add_bc_params = map { 'barcode_'.$_->id => 'BC'.$_->id } $tmp_piq_plate->wells;
    ok my $messages = add_barcodes_to_wells(model, \%add_bc_params, 'checked_out'), "Barcodes added to PIQ wells";
    my @piq_wells = $tmp_piq_plate->wells;
    foreach my $well(@piq_wells){
        is $well->well_barcode->barcode,'BC'.$well->id, "New well barcode is correct";
        is $well->well_barcode->barcode_state->id, 'checked_out', "New well barcode has correct state";
        is $well->well_barcode->root_piq_well_id, $qc_well->id, "New well linked to root piq well ID";
    }

    # create new PIQ plate by csv upload
    my $a01_bc = $piq_wells[0]->well_barcode->barcode;
    my $a02_bc = $piq_wells[1]->well_barcode->barcode;
    my %location_of_barcode;
    my $fh = tempfile();
    print $fh "A01,$a01_bc\nA02,$a02_bc\n";
    $fh->seek(0,0);
    ok my ($new_piq_plate, $piq_messages) = upload_plate_scan(model,{
        new_plate_name => 'NEW_PIQ_TEST',
        species => 'Human',
        user => 'test_user@example.org',
        csv_fh => $fh,
        new_state => 'in_freezer',
    }), "New PIQ plate created from csv upload";

    is $new_piq_plate->type_id, "PIQ", "New plate type correct";
    is scalar($new_piq_plate->wells), 2, "New plate has 2 wells";
    ok my $a01 = $new_piq_plate->search_related('wells',{ name => 'A01' })->first, "A01 found on new plate";
    is $a01->well_barcode->barcode, $a01_bc, "A01 barcode is correct";
    is $a01->well_barcode->barcode_state->id, "in_freezer", "A01 barcode state correct";
    like $a01->well_lab_number->lab_number, qr/$params->{lab_number}/, "A01 well lab number correct";
    is $a01->well_barcode->root_piq_well_id, $qc_well->id, "A01 barcode linked to root piq well ID";
    my ($a01_parent) = $a01->parent_wells;
    is $a01_parent->id, $piq_wells[0]->id, "A01 has correct parent well";

}

sub individual_checkout_tests : Tests(){
    my $bc = 11;
    my $unchanged_well = 'B01';

    # Fetch the barcode and one other well from the same plate
    ok my $well_bc = model->retrieve_well_barcode({ barcode => $bc }), "Barcode $bc found";
    my $well_name = $well_bc->well->name;
    my $orig_plate = $well_bc->well->plate;

    is scalar($well_bc->well->plate->wells), 47, "Original plate has 47 wells";
    is $well_bc->well->plate->version, undef, "Original plate has no version number";
    ok my $orig_unchanged = $well_bc->well->plate->search_related('wells',{ name => $unchanged_well })->first, "$unchanged_well found";

    # Do the checkout
    ok my $checkout_bc = checkout_well_barcode(model, { barcode => $bc, user => 'test_user@example.org' });
    is $checkout_bc->barcode_state->id, 'checked_out', "Barcode is now checked out";

    # update the orig plate info from DB
    $orig_plate->discard_changes();

    is scalar($orig_plate->wells), 47, "Original plate still has 47 wells";
    is $orig_plate->id, $checkout_bc->well->plate->id, "Checked out barcode remains on original plate";
    ok defined($orig_plate->version), "Original plate now has a version number";

    # get the new plate with same name
    ok my $new_plate = model->retrieve_plate({ name => $orig_plate->name, version => undef });
    is scalar($new_plate->wells), 46, "New plate version has 46 wells";
    is $new_plate->version, undef, "New plate has no version number";
    my $discarded_well = $new_plate->search_related('wells',{ name => $well_name })->first;
    is $discarded_well, undef, "$well_name is not on new plate";
    ok my $new_unchanged = $well_bc->well->plate->search_related('wells',{ name => $unchanged_well })->first, "$unchanged_well found";
}

1;
