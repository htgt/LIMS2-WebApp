ALTER TABLE summaries ADD COLUMN ancestor_piq_plate_name text;
ALTER TABLE summaries ADD COLUMN ancestor_piq_plate_id integer;
ALTER TABLE summaries ADD COLUMN ancestor_piq_well_name text;
ALTER TABLE summaries ADD COLUMN ancestor_piq_well_id integer;
ALTER TABLE summaries ADD COLUMN ancestor_piq_well_created_ts timestamp without time zone;
ALTER TABLE summaries ADD COLUMN ancestor_piq_well_accepted boolean;
