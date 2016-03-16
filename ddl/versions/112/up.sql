alter table wells alter column name drop not null;
alter table wells alter column plate_id drop not null;

alter table wells add column barcode VARCHAR(40) UNIQUE;
alter table wells ADD COLUMN barcode_state TEXT REFERENCES barcode_states(id);
alter table wells ADD CONSTRAINT barcode_if_no_location CHECK ( (plate_id is null and barcode is not null) OR (plate_id is not null) );

alter table barcode_events add column old_well_name text;
alter table barcode_events add column new_well_name text;
alter table barcode_events add column old_plate_id integer REFERENCES plates(id);
alter table barcode_events add column new_plate_id integer REFERENCES plates(id);
