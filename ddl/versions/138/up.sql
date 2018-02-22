CREATE TABLE miseq_design_presets (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    min_gc INTEGER,
    max_gc INTEGER,
    opt_gc INTEGER,
    min_mt INTEGER,
    max_mt INTEGER,
    opt_mt INTEGER
);

CREATE TABLE miseq_primer_parameters (
    id SERIAL PRIMARY KEY,
    internal boolean NOT NULL,
    min_length INTEGER,
    max_length INTEGER,
    opt_length INTEGER
);
