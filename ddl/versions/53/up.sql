CREATE TABLE design_attempts (
    id                SERIAL PRIMARY KEY,
    design_parameters TEXT,
    gene_id           TEXT,
    status            TEXT,
    fail              TEXT,
    error             TEXT,
    design_ids        TEXT,
    species_id        TEXT NOT NULL REFERENCES species(id),
    created_by        INTEGER NOT NULL REFERENCES users(id),
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    comment           TEXT
);
