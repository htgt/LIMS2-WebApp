CREATE TABLE crispr_loci_types (
    id TEXT PRIMARY KEY
);
GRANT SELECT ON crispr_loci_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON crispr_loci_types TO "[% rw_role %]";

CREATE TABLE crisprs (
    id                   SERIAL PRIMARY KEY,
    seq                  TEXT NOT NULL,
    species_id           TEXT NOT NULL REFERENCES species(id),
    crispr_loci_type_id  TEXT NOT NULL REFERENCES crispr_loci_types(id),
    off_target_outlier   BOOL NOT NULL,
    comment              TEXT NOT NULL
);
GRANT SELECT ON crisprs TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON crisprs TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE crisprs_id_seq TO "[% rw_role %]";

CREATE TABLE crispr_loci (
    id                    SERIAL PRIMARY KEY,
    crispr_id             INTEGER NOT NULL REFERENCES crisprs(id),
    assembly_id           TEXT NOT NULL REFERENCES assemblies(id),
    chr_id                INTEGER NOT NULL REFERENCES chromosomes(id),
    chr_start             INTEGER NOT NULL,
    chr_end               INTEGER NOT NULL,
    chr_strand            INTEGER NOT NULL CHECK ( chr_strand IN (1,-1) ),
    CONSTRAINT crispr_loci_start_end_check CHECK (chr_start <= chr_end)
);
GRANT SELECT ON crispr_loci TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON crispr_loci TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE crispr_loci_id_seq TO "[% rw_role %]";

CREATE TABLE crispr_off_targets (
    id                    SERIAL PRIMARY KEY,
    crispr_id             INTEGER NOT NULL REFERENCES crisprs(id),
    crispr_loci_type_id   TEXT NOT NULL REFERENCES crispr_loci_types(id),
    assembly_id           TEXT NOT NULL REFERENCES assemblies(id),
    build_id              INTEGER NOT NULL,
    chr_id                INTEGER NOT NULL REFERENCES chromosomes(id),
    chr_start             INTEGER NOT NULL,
    chr_end               INTEGER NOT NULL,
    chr_strand            INTEGER NOT NULL CHECK ( chr_strand IN (1,-1) ),
    CONSTRAINT crispr_loci_start_end_check CHECK (chr_start <= chr_end)
);
GRANT SELECT ON crispr_off_targets TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON crispr_off_targets TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE crispr_off_targets_id_seq TO "[% rw_role %]";

CREATE TABLE process_crispr (
       process_id      INTEGER PRIMARY KEY REFERENCES processes(id),
       crispr_id       INTEGER NOT NULL REFERENCES crisprs(id)
);
GRANT SELECT ON process_crispr TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_crispr TO "[% rw_role %]";
