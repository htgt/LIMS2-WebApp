CREATE TABLE miseq_alleles_frequency (
    id SERIAL PRIMARY KEY NOT NULL,
    miseq_well_experiment_id integer REFERENCES miseq_well_experiment(id),
    aligned_sequence text,
    nhej boolean NOT NULL DEFAULT FALSE, 
    unmodified boolean NOT NULL DEFAULT FALSE,
    hdr boolean NOT NULL DEFAULT FALSE,
    n_deleted integer NOT NULL DEFAULT -1,
    n_mutated integer NOT NULL DEFAULT -1,
    n_reads integer NOT NULL DEFAULT -1
    );

ALTER TABLE miseq_well_experiment
    ADD COLUMN indel_size_distribution_graph BYTEA;

ALTER TABLE miseq_experiment 
    RENAME COLUMN mutation_reads TO nheg_reads;

ALTER TABLE miseq_experiment
    ADD COLUMN hdr_reads integer,
    ADD COLUMN mixed_reads integer;


