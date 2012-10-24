ALTER TABLE qc_template_wells
ADD COLUMN source_well_id INTEGER;

ALTER TABLE qc_template_wells
ADD FOREIGN KEY (source_well_id) REFERENCES wells(id);
