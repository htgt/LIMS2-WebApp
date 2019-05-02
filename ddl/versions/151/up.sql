AlTER TABLE miseq_alleles_frequency
    ADD COLUMN reference_sequence text,
    ADD COLUMN quality_score text;

ALTER TABLE crispresso_submissions ALTER COLUMN date_stamp TYPE timestamp without time zone USING date_stamp::timestamp without time zone;
ALTER TABLE crispresso_submissions ALTER COLUMN date_stamp SET NOT NULL;
ALTER TABLE crispresso_submissions ALTER COLUMN date_stamp SET DEFAULT now();
ALTER TABLE crispresso_submissions RENAME COLUMN id to miseq_well_exp_id;
