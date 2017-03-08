CREATE TABLE miseq_experiment (
    id serial primary key NOT NULL,
    miseq_id integer REFERENCES miseq_projects(id) NOT NULL,
    name text NOT NULL,
    gene text,
    mutation_reads integer,
    total_reads integer
);

ALTER TABLE miseq_project_well_exp ADD CONSTRAINT miseq_well_id_fkey FOREIGN KEY (miseq_well_id) REFERENCES miseq_project_well(id);
ALTER TABLE miseq_project_well_exp RENAME COLUMN experiment TO miseq_exp_id;
