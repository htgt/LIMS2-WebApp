ALTER TABLE audit.crispresso_submissions ALTER COLUMN date_stamp TYPE timestamp without time zone USING date_stamp::timestamp without time zone;
ALTER TABLE audit.miseq_alleles_frequency ADD COLUMN reference_sequence text;
ALTER TABLE audit.miseq_alleles_frequency ADD COLUMN quality_score text;
ALTER TABLE audit.crispresso_submissions ADD COLUMN miseq_well_exp_id integer;
ALTER TABLE audit.crispresso_submissions DROP COLUMN id;
