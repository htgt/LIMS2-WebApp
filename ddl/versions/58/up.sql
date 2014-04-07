CREATE TABLE crispr_es_qc_runs (
    id                     CHAR(36) PRIMARY KEY,
    sequencing_project     TEXT NOT NULL,
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_id          INTEGER NOT NULL REFERENCES users(id),
    species_id             TEXT NOT NULL REFERENCES species(id)
);

CREATE TABLE crispr_es_qc_wells (
    id                     INTEGER PRIMARY KEY,
    crispr_es_qc_run_id    CHAR(36) NOT NULL REFERENCES crispr_es_qc_runs(id),
    well_id                INTEGER NOT NULL REFERENCES wells(id),
    fwd_read               TEXT NOT NULL,
    rev_read               TEXT NOT NULL,
    crispr_chr_id          INTEGER NOT NULL REFERENCES chromosomes(id),
    crispr_start           INTEGER NOT NULL,
    crispr_end             INTEGER NOT NULL,
    comment                TEXT,
    analysis_data          TEXT NOT NULL
);
