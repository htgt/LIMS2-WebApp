CREATE TABLE design_create (
    id                SERIAL PRIMARY KEY,
    design_parameters TEXT,
    gene_id           TEXT,
    status            TEXT,
    fail              TEXT,
    error             TEXT,
    design_ids        TEXT, 
    created_by        INTEGER NOT NULL REFERENCES users(id),
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    comment           TEXT 
);
