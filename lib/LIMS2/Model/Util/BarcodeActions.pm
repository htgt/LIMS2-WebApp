package LIMS2::Model::Util::BarcodeActions;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [
        qw(
              discard_barcode
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq );
use LIMS2::Exception;

sub discard_barcode{
	# input: model, barcode, user, reason

	# set well barcode state to "discarded" (use update_well_barcode from model plugin)

	# find plate on which barcode well resides

	# rename existing plate to XXXX_vN
	# create new plate called XXXX which is exact copy of old but without discarded well
	  # create new plate
	  # create new wells which are rearray of old wells (minus discarded one)
	  # change well_barcode well_ids for all barcodes from old to new wells
}

sub remove_well_barcodes_from_plate{
  # rename existing plate
  # create new well name->barcode hash
  # created_barcoded_plate_copy
}

sub add_well_barcodes_to_plate{
  # rename existing plate
  # create new well name->barcode hash
  # created_barcoded_plate_copy
}

sub move_well_barcodes_within_plate{
  # rename existing plate
  # create new well name->barcode hash
  # created_barcoded_plate_copy
}

sub move_well_barcodes_between_plates{
  # rename all existing plates changed
  # create new well name->barcode hash for each plate
  # created_barcoded_plate_copy for each plate
}

# Generic method to create a new plate with barcodes at specified positions
# Each barcode's current well location will be identified
# New wells will be parented off them
# Process is always rearray
# well_barcode table will be updated (can provide comment for the barcode event table at this point if needed)
sub create_barcoded_plate_copy{
    # input: new plate name, hash of well names to barcodes, user

    # NB: if barcodes do not already exist we need to handle them in a different method
    # which can handle parent well and process info (probably just the standard plate create method)
}