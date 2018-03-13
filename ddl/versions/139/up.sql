CREATE TABLE miseq_design_presets (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_by INTEGER REFERENCES users(id) NOT NULL,
    genomic_threshold INTEGER,
    min_gc INTEGER,
    max_gc INTEGER,
    opt_gc INTEGER,
    min_mt INTEGER,
    max_mt INTEGER,
    opt_mt INTEGER
);

CREATE TABLE miseq_primer_presets (
    id SERIAL PRIMARY KEY,
    preset_id INTEGER REFERENCES miseq_design_presets(id),
    internal boolean NOT NULL,
    search_width INTEGER,
    offset_width INTEGER,
    increment_value INTEGER
);
