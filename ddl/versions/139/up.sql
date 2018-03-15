CREATE TABLE miseq_design_presets (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_by INTEGER REFERENCES users(id) NOT NULL,
    genomic_threshold INTEGER NOT NULL,
    min_gc INTEGER NOT NULL,
    max_gc INTEGER NOT NULL,
    opt_gc INTEGER NOT NULL,
    min_mt INTEGER NOT NULL,
    max_mt INTEGER NOT NULL,
    opt_mt INTEGER NOT NULL
);

CREATE TABLE miseq_primer_presets (
    id SERIAL PRIMARY KEY,
    preset_id INTEGER REFERENCES miseq_design_presets(id) NOT NULL,
    internal boolean NOT NULL,
    search_width INTEGER NOT NULL,
    offset_width INTEGER NOT NULL,
    increment_value INTEGER NOT NULL
);
