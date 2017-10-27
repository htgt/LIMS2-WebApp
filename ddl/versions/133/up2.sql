ALTER TABLE miseq_experiment RENAME COLUMN gene TO experiment_id;
ALTER TABLE miseq_experiment ADD CONSTRAINT experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES experiments(id);
