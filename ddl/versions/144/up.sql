ALTER TABLE miseq_experiment DROP COLUMN IF EXISTS gene;
ALTER TABLE miseq_experiment ADD COLUMN experiment_id int REFERENCES experiments(id);
ALTER TABLE miseq_experiment ADD COLUMN parent_plate_id int REFERENCES plates(id);
