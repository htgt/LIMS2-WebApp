--
-- Constrained vocabulary for assemblies and chromosomes
--
CREATE TABLE assemblies (
       id     TEXT PRIMARY KEY
);
GRANT SELECT ON assemblies TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON assemblies TO "[% rw_role %]";

CREATE TABLE chromosomes (
       id     TEXT PRIMARY KEY
);
GRANT SELECT ON chromosomes TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON chromosomes TO "[% rw_role %]";

--
-- BAC data
--

CREATE TABLE bac_libraries (
       id    TEXT PRIMARY KEY
);
GRANT SELECT ON bac_libraries TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON bac_libraries TO "[% rw_role %]";

CREATE TABLE bac_clones (
       id               SERIAL PRIMARY KEY,
       name             TEXT NOT NULL,
       bac_library_id   TEXT NOT NULL REFERENCES bac_libraries(id),
       UNIQUE (name, bac_library_id)
);
GRANT SELECT ON bac_clones TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON bac_clones TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE bac_clones_id_seq TO "[% rw_role %]";

CREATE TABLE bac_clone_loci (
       bac_clone_id     INTEGER NOT NULL REFERENCES bac_clones(id),
       assembly_id      TEXT NOT NULL REFERENCES assemblies(id),
       chr_id           TEXT NOT NULL REFERENCES chromosomes(id),
       chr_start        INTEGER NOT NULL,
       chr_end          INTEGER NOT NULL,
       PRIMARY KEY(bac_clone_id, assembly_id),
       CHECK (chr_end > chr_start )
);
GRANT SELECT ON bac_clone_loci TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON bac_clone_loci TO "[% rw_role %]";

--
-- Design data
--

CREATE TABLE design_types (
       id    TEXT PRIMARY KEY
);
GRANT SELECT ON design_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON design_types TO "[% rw_role %]";

CREATE TABLE designs (
       id                       INTEGER PRIMARY KEY,
       name                     TEXT,
       created_by               INTEGER NOT NULL REFERENCES users(id),
       created_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       design_type_id           TEXT NOT NULL REFERENCES design_types(id),
       phase                    INTEGER NOT NULL CHECK (phase IN (-1, 0, 1, 2)),
       validated_by_annotation  TEXT NOT NULL CHECK (validated_by_annotation IN ( 'yes', 'no', 'maybe', 'not done' )),
       target_transcript        TEXT
);
GRANT SELECT ON designs TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON designs TO "[% rw_role %]";

CREATE INDEX ON designs(target_transcript);

CREATE TABLE gene_design (
       gene_id           TEXT NOT NULL,
       design_id         INTEGER NOT NULL REFERENCES designs(id),
       created_by        INTEGER NOT NULL REFERENCES users(id),
       created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       PRIMARY KEY(gene_id, design_id)
);
GRANT SELECT ON gene_design TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON gene_design TO "[% rw_role %]";

CREATE INDEX ON gene_design(gene_id);
CREATE INDEX ON gene_design(design_id);

CREATE TABLE design_oligo_types (
       id TEXT PRIMARY KEY
);

GRANT SELECT ON design_oligo_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON design_oligo_types TO "[% rw_role %]";

CREATE TABLE design_oligos (
       id                   SERIAL PRIMARY KEY,
       design_id            INTEGER NOT NULL REFERENCES designs(id),
       design_oligo_type_id TEXT NOT NULL REFERENCES design_oligo_types(id),
       seq                  TEXT NOT NULL,
       UNIQUE(design_id, design_oligo_type_id)
);

GRANT SELECT ON design_oligos TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON design_oligos TO "[% rw_role %]";
GRANT USAGE ON desgin_oligos_id_seq TO "[% rw_role %]";

CREATE TABLE design_oligo_loci (
       design_oligo_id      INTEGER NOT NULL REFERENCES design_oligos(id),
       assembly_id          TEXT NOT NULL REFERENCES assemblies(id),
       chr_id               TEXT NOT NULL REFERENCES chromosomes(id),
       chr_start            INTEGER NOT NULL,
       chr_end              INTEGER NOT NULL,
       chr_strand           INTEGER NOT NULL CHECK (chr_strand IN (1, -1)),
       PRIMARY KEY (design_oligo_id, assembly_id),
       CHECK ( chr_start <= chr_end )
);

GRANT SELECT ON design_oligo_loci TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON design_oligo_loci TO "[% rw_role %]";

CREATE TABLE design_comment_categories (
       id   SERIAL PRIMARY KEY,
       name TEXT NOT NULL UNIQUE
);
GRANT SELECT ON design_comment_categories TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON design_comment_categories TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE design_comment_categories_id_seq TO "[% rw_role %]";

CREATE TABLE design_comments (
       id                         SERIAL PRIMARY KEY,
       design_comment_category_id INTEGER NOT NULL REFERENCES design_comment_categories(id),
       design_id                  INTEGER NOT NULL REFERENCES designs(id),
       comment_text               TEXT NOT NULL DEFAULT '',
       is_public                  BOOLEAN NOT NULL DEFAULT FALSE,
       created_by                 INTEGER NOT NULL REFERENCES users(id),
       created_at                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
GRANT SELECT ON design_comments TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON design_comments TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE design_comments_id_seq TO "[% rw_role %]";

CREATE TABLE genotyping_primer_types (
       id TEXT PRIMARY KEY
);
GRANT SELECT ON genotyping_primer_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON genotyping_primer_types TO "[% rw_role %]";

CREATE TABLE genotyping_primers (
       id                        SERIAL PRIMARY KEY,
       genotyping_primer_type_id TEXT NOT NULL REFERENCES genotyping_primer_types(id),
       design_id                 INTEGER NOT NULL REFERENCES designs(id),
       seq                       TEXT NOT NULL
);
GRANT SELECT ON genotyping_primers TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON genotyping_primers TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE genotyping_primers_id_seq TO "[% rw_role %]";
