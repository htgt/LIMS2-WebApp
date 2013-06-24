CREATE TABLE design_targets (
    id                      SERIAL PRIMARY KEY,
    gene_name               TEXT NOT NULL,
    ensembl_gene_id         TEXT NOT NULL,
    ensembl_exon_id         TEXT NOT NULL,
    exon_size               INTEGER NOT NULL,
    exon_rank               INTEGER,
    canonical_transcript    TEXT,
    species_id              TEXT NOT NULL REFERENCES species(id),
    assembly_id             TEXT NOT NULL REFERENCES assemblies(id),
    build_id                INTEGER NOT NULL,
    chr_id                  INTEGER NOT NULL REFERENCES chromosomes(id),
    chr_start               INTEGER NOT NULL,
    chr_end                 INTEGER NOT NULL,
    chr_strand              INTEGER NOT NULL CHECK ( chr_strand IN (1,-1) ),
    automatically_picked    BOOL NOT NULL,
    comment                 TEXT
);
GRANT SELECT ON design_targets TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON design_targets TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE design_targets_id_seq TO "[% rw_role %]";
