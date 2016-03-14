ALTER TABLE audit.barcode_events DROP COLUMN new_well_id;
ALTER TABLE audit.barcode_events DROP COLUMN old_well_id;
DROP TABLE audit.well_barcodes;
