ALTER TABLE well_primer_bands ALTER COLUMN pass TYPE VARCHAR(16);
ALTER TABLE well_primer_bands ALTER COLUMN pass DROP DEFAULT;
ALTER TABLE well_primer_bands ALTER COLUMN pass SET NOT NULL;
