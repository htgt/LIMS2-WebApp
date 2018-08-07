ALTER TABLE miseq_experiment DROP COLUMN IF EXISTS gene;
ALTER TABLE miseq_experiment ADD COLUMN experiment_id int references experiments(id);
