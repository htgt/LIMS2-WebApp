ALTER TABLE miseq_project_well_exp ALTER COLUMN miseq_exp_id TYPE integer USING (miseq_exp_id::integer);
ALTER TABLE miseq_project_well_exp ADD CONSTRAINT miseq_exp_id_fkey FOREIGN KEY (miseq_exp_id) REFERENCES miseq_experiment(id);
