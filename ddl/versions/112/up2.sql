UPDATE wells SET barcode = (
	SELECT barcode FROM well_barcodes where wells.id = well_barcodes.well_id
);

UPDATE wells SET barcode_state = (
	SELECT barcode_state FROM well_barcodes where wells.id = well_barcodes.well_id
);

update barcode_events set old_well_name = (
	select name from wells where wells.id = barcode_events.old_well_id
);

update barcode_events set new_well_name = (
	select name from wells where wells.id = barcode_events.new_well_id
);

update barcode_events set old_plate_id = (
	select plate_id from wells where wells.id = barcode_events.old_well_id
);

update barcode_events set new_plate_id = (
	select plate_id from wells where wells.id = barcode_events.new_well_id
);

alter table barcode_events drop column old_well_id;
alter table barcode_events drop column new_well_id;

alter table barcode_events ADD CONSTRAINT barcode_events_barcode_in_wells_fkey foreign key (barcode) references wells(barcode);
alter table barcode_events DROP CONSTRAINT barcode_events_barcode_fkey;

alter table fp_picking_list_well_barcode ADD CONSTRAINT fp_picking_list_well_barcode_barcode_fkey FOREIGN KEY (well_barcode) REFERENCES wells(barcode);
alter table fp_picking_list_well_barcode DROP CONSTRAINT fp_picking_list_well_barcode_well_barcode_fkey;

DROP TABLE well_barcodes;