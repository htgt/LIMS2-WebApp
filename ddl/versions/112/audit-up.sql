ALTER TABLE audit.wells ADD COLUMN barcode character varying;
ALTER TABLE audit.wells ADD COLUMN barcode_state text;
ALTER TABLE audit.barcode_events ADD COLUMN old_well_name text;
ALTER TABLE audit.barcode_events ADD COLUMN new_well_name text;
ALTER TABLE audit.barcode_events ADD COLUMN old_plate_id integer;
ALTER TABLE audit.barcode_events ADD COLUMN new_plate_id integer;
