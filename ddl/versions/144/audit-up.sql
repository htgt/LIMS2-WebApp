ALTER TABLE audit.miseq_experiment ADD COLUMN experiment_id integer;
ALTER TABLE audit.miseq_experiment DROP COLUMN gene;
