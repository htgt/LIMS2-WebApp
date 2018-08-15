CREATE TABLE miseq_alleles_frequency (
    id SERIAL PRIMARY KEY NOT NULL,
    miseq_well_experiment_id integer REFERENCES miseq_well_experiment(id),
    aligned_sequence text,
    nhej boolean NOT NULL DEFAULT FALSE, 
    unmodified boolean NOT NULL DEFAULT FALSE,
    hdr boolean NOT NULL DEFAULT FALSE,
    n_deleted integer NOT NULL DEFAULT 0,
    n_inserted integer NOT NULL DEFAULT 0,
    n_mutated integer NOT NULL DEFAULT 0,
    n_reads integer NOT NULL DEFAULT 0 
);



CREATE TABLE indel_distribution_graph (
    id integer PRIMARY KEY NOT NULL REFERENCES miseq_well_experiment(id),
    indel_size_distribution_graph BYTEA
);

AlTER TABLE miseq_well_experiment
    ADD COLUMN total_reads integer;
    
ALTER TABLE miseq_experiment 
    RENAME COLUMN mutation_reads TO nhej_reads;

ALTER TABLE miseq_experiment
    ADD COLUMN hdr_reads integer,
    ADD COLUMN mixed_reads integer;
