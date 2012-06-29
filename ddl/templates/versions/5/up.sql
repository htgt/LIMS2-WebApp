--
-- Schema for plates, wells, and processes
--

CREATE TABLE plate_types (
       id          TEXT PRIMARY KEY,
       description TEXT NOT NULL DEFAULT ''
);
GRANT SELECT ON plate_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON plate_types TO "[% rw_role %]";

CREATE TABLE plates (
       id               SERIAL PRIMARY KEY,
       name             TEXT NOT NULL UNIQUE,
       description      TEXT NOT NULL DEFAULT '',
       type_id          TEXT NOT NULL REFERENCES plate_types(id),
       created_by_id    INTEGER NOT NULL REFERENCES users(id),
       created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
GRANT SELECT ON plates TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON plates TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE plates_id_seq TO "[% rw_role %]";

CREATE TABLE plate_comments (
       id                   SERIAL PRIMARY KEY,
       plate_id             INTEGER NOT NULL REFERENCES plates(id),
       comment_text         TEXT NOT NULL CHECK (comment_text <> ''),
       created_by_id        INTEGER NOT NULL REFERENCES users(id),
       created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

GRANT SELECT ON plate_comments TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON plate_comments TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE plate_comments_id_seq TO "[% rw_role %]";

CREATE TABLE wells (
       id               SERIAL PRIMARY KEY,
       plate_id         INTEGER NOT NULL REFERENCES plates(id),
       name             TEXT NOT NULL,
       created_by_id    INTEGER NOT NULL REFERENCES users(id),
       created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       assay_pending    TIMESTAMP,
       assay_complete   TIMESTAMP,
       accepted         BOOLEAN NOT NULL DEFAULT FALSE,
       UNIQUE( plate_id, name )
);
GRANT SELECT ON wells TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON wells TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE wells_id_seq TO "[% rw_role %]";

CREATE TABLE well_accepted_override (
       well_id             INTEGER PRIMARY KEY REFERENCES wells(id),
       accepted            BOOLEAN NOT NULL,
       created_by_id       INTEGER NOT NULL REFERENCES users(id),
       created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
GRANT SELECT ON well_accepted_override TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_accepted_override TO "[% rw_role %]";

CREATE TABLE well_comments (
       id                  SERIAL PRIMARY KEY,
       well_id             INTEGER NOT NULL REFERENCES wells(id),
       comment_text        TEXT NOT NULL,
       created_by_id       INTEGER NOT NULL REFERENCES users(id),
       created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
GRANT SELECT ON well_comments TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_comments TO "[% rw_role %]";
GRANT USAGE ON well_comments_id_seq TO "[% rw_role %]";

CREATE TABLE process_types (
       id            TEXT PRIMARY KEY,
       description   TEXT NOT NULL DEFAULT ''
);
GRANT SELECT ON process_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_types TO "[% rw_role %]";

CREATE TABLE processes (
       id              SERIAL PRIMARY KEY,
       type_id         TEXT NOT NULL REFERENCES process_types(id)
);
GRANT SELECT ON processes TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON processes TO "[% rw_role %]";
GRANT USAGE ON processes_id_seq TO "[% rw_role %]";

CREATE TABLE process_input_well (
       process_id      INTEGER NOT NULL REFERENCES processes(id),
       well_id         INTEGER NOT NULL REFERENCES wells(id),
       PRIMARY KEY(process_id, well_id)
);
GRANT SELECT ON process_input_well TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_input_well TO "[% rw_role %]";

CREATE TABLE process_output_well (
       process_id      INTEGER NOT NULL REFERENCES processes(id),
       well_id         INTEGER NOT NULL REFERENCES wells(id),
       PRIMARY KEY(process_id, well_id)
);
GRANT SELECT ON process_output_well TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_output_well TO "[% rw_role %]";

CREATE TABLE process_design (
       process_id      INTEGER PRIMARY KEY REFERENCES processes(id),
       design_id       INTEGER NOT NULL REFERENCES designs(id)
);
GRANT SELECT ON process_design TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_design TO "[% rw_role %]";

CREATE TABLE process_cassette (
       process_id      INTEGER PRIMARY KEY REFERENCES processes(id),
       cassette        TEXT NOT NULL
);
GRANT SELECT ON process_cassette TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_cassette TO "[% rw_role %]";

CREATE TABLE process_backbone (
       process_id      INTEGER PRIMARY KEY REFERENCES processes(id),
       backbone        TEXT NOT NULL
);
GRANT SELECT ON process_backbone TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_backbone TO "[% rw_role %]";

CREATE TABLE process_bac (
       process_id        INTEGER NOT NULL REFERENCES processes(id),
       bac_plate         TEXT NOT NULL,
       bac_clone_id      INTEGER NOT NULL REFERENCES bac_clones(id),
       PRIMARY KEY(process_id,bac_plate)
);
GRANT SELECT ON process_bac TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_bac TO "[% rw_role %]";

CREATE TABLE recombinases (
       id               TEXT PRIMARY KEY
);
GRANT SELECT ON recombinases TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON recombinases TO "[% rw_role %]";

CREATE TABLE process_recombinase (
       process_id        INTEGER NOT NULL REFERENCES processes(id),
       recombinase_id    TEXT NOT NULL REFERENCES recombinases(id),
       rank              INTEGER NOT NULL,
       PRIMARY KEY(process_id,rank),
       UNIQUE(process_id, recombinase)
);
GRANT SELECT ON process_recombinase TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_recombinase TO "[% rw_role %]";

CREATE TABLE recombineering_result_types (
       id TEXT PRIMARY KEY
);       
GRANT SELECT ON recombineering_result_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON recombineering_result_types TO "[% rw_role %]";

CREATE TABLE well_recombineering_results (
       well_id             INTEGER NOT NULL REFERENCES wells(id),
       result_type_id      TEXT NOT NULL REFERENCES recombineering_result_types(id),
       result              TEXT NOT NULL CHECK (result IN ( 'pass', 'fail', 'weak' )),
       comment_text        TEXT NOT NULL DEFAULT '',
       created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id       INTEGER NOT NULL REFERENCES users(id),
       PRIMARY KEY(well_id, result_type_id)
);       
GRANT SELECT ON well_recombineering_results TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_recombineering_results TO "[% rw_role %]";

CREATE TABLE well_dna_status (
       well_id             INTEGER PRIMARY KEY REFERENCES wells(id),
       pass                BOOLEAN NOT NULL,
       comment_text        TEXT NOT NULL DEFAULT '',
       created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id       INTEGER NOT NULL REFERENCES users(id)
);
GRANT SELECT ON well_dna_status TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_dna_status TO "[% rw_role %]";

CREATE TABLE well_dna_quality (
       well_id             INTEGER PRIMARY KEY REFERENCES wells(id),
       quality             TEXT NOT NULL CHECK (quality IN ('L', 'M', 'ML', 'S', 'U')),
       comment_text        TEXT NOT NULL DEFAULT '',
       created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id       INTEGER NOT NULL REFERENCES users(id)
);
GRANT SELECT ON well_dna_quality TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_dna_quality TO "[% rw_role %]";
       
CREATE TABLE well_qc_sequencing_result (
       well_id             INTEGER PRIMARY KEY REFERENCES wells(id),
       valid_primers       TEXT NOT NULL DEFAULT '',
       mixed_reads         BOOLEAN NOT NULL DEFAULT FALSE,
       pass                BOOLEAN NOT NULL DEFAULT FALSE,
       test_result_url     TEXT NOT NULL       
);
GRANT SELECT ON well_qc_sequencing_result TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_qc_sequencing_result TO "[% rw_role %]";
