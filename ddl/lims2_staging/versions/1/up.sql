
        
--
-- Initial schema version. Contains tables to store users, roles and qc data
--

--
-- Schema metadata
--
CREATE TABLE schema_versions (
       version      INTEGER NOT NULL,
       deployed_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       PRIMARY KEY (version, deployed_at)
);
GRANT SELECT ON schema_versions TO "lims2_staging_ro", "lims2_staging_rw";

--
-- Users and roles
--
CREATE TABLE users (
       id        SERIAL PRIMARY KEY,
       name      TEXT NOT NULL UNIQUE CHECK (name <> ''),
       password  TEXT
);
GRANT SELECT ON users TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO "lims2_staging_rw";
GRANT USAGE ON SEQUENCE users_id_seq TO "lims2_staging_rw";

CREATE TABLE roles (
       id    SERIAL PRIMARY KEY,
       name  TEXT NOT NULL UNIQUE CHECK (name <> '')
);
GRANT SELECT ON roles TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON roles TO "lims2_staging_rw";
GRANT USAGE ON SEQUENCE roles_id_seq TO "lims2_staging_rw";

CREATE TABLE user_role (
       user_id INTEGER NOT NULL REFERENCES users(id),
       role_id INTEGER NOT NULL REFERENCES roles(id),
       PRIMARY KEY (user_id, role_id)
);
GRANT SELECT ON user_role TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON user_role TO "lims2_staging_rw";

--
-- Data for sequencing QC
--
CREATE TABLE qc_eng_seqs (
    id                SERIAL PRIMARY KEY,
    method            TEXT NOT NULL,
    params            TEXT NOT NULL,
    UNIQUE ( method, params )
);
GRANT SELECT ON qc_eng_seqs TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_eng_seqs TO "lims2_staging_rw";
GRANT USAGE ON SEQUENCE qc_eng_seqs_id_seq TO "lims2_staging_rw";

CREATE TABLE qc_templates (
       id            SERIAL PRIMARY KEY,
       name          TEXT NOT NULL,
       created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       UNIQUE (name, created_at)
);
GRANT SELECT ON qc_templates TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_templates TO "lims2_staging_rw";
GRANT USAGE ON SEQUENCE qc_templates_id_seq TO "lims2_staging_rw";

CREATE TABLE qc_template_wells (
       id                     SERIAL PRIMARY KEY,
       qc_template_id         INTEGER NOT NULL REFERENCES qc_templates(id),
       name                   TEXT NOT NULL CHECK (name ~ '^[A-O](0[1-9]|1[0-9]|2[0-4])$'),
       qc_eng_seq_id          INTEGER NOT NULL REFERENCES qc_eng_seqs(id),
       UNIQUE (qc_template_id, name)
);
GRANT SELECT ON qc_template_wells TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_template_wells TO "lims2_staging_rw";
GRANT USAGE ON SEQUENCE qc_template_wells_id_seq TO "lims2_staging_rw";

CREATE TABLE qc_runs (
       id                     CHAR(36) PRIMARY KEY,
       created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id          INTEGER NOT NULL REFERENCES users(id),
       profile                TEXT NOT NULL,
       qc_template_id         INTEGER NOT NULL REFERENCES qc_templates(id),
       software_version       TEXT NOT NULL,
       upload_complete        BOOLEAN NOT NULL DEFAULT FALSE                              
);
GRANT SELECT ON qc_runs TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_runs TO "lims2_staging_rw";

CREATE TABLE qc_seq_projects (
       id TEXT PRIMARY KEY
);
GRANT SELECT ON qc_seq_projects TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_seq_projects TO "lims2_staging_rw";

CREATE TABLE qc_seq_project_wells (
       id                  SERIAL PRIMARY KEY,
       qc_seq_project_id   TEXT NOT NULL REFERENCES qc_seq_projects(id),
       plate_name          TEXT NOT NULL,
       well_name           TEXT NOT NULL,
       UNIQUE(qc_seq_project_id,plate_name,well_name)
);
GRANT SELECT ON qc_seq_project_wells TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_seq_project_wells TO "lims2_staging_rw";
GRANT USAGE ON qc_seq_project_wells_id_seq TO "lims2_staging_rw";

CREATE TABLE qc_seq_reads (
       id                     TEXT PRIMARY KEY,
       description            TEXT NOT NULL DEFAULT '',
       qc_seq_project_well_id INTEGER NOT NULL REFERENCES qc_seq_project_wells(id),
       primer_name            TEXT NOT NULL,
       seq                    TEXT NOT NULL,
       length                 INTEGER NOT NULL       
);
GRANT SELECT ON qc_seq_reads TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_seq_reads TO "lims2_staging_rw";

CREATE INDEX ON qc_seq_reads(qc_seq_project_well_id);

CREATE TABLE qc_run_seq_project (
       qc_run_id               CHAR(36) NOT NULL REFERENCES qc_runs(id),
       qc_seq_project_id       TEXT NOT NULL REFERENCES qc_seq_projects(id),
       PRIMARY KEY(qc_run_id, qc_seq_project_id)
);
GRANT SELECT ON qc_run_seq_project TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_run_seq_project TO "lims2_staging_rw";

CREATE TABLE qc_test_results (
       id                      SERIAL PRIMARY KEY,
       qc_run_id               CHAR(36) NOT NULL REFERENCES qc_runs(id),
       qc_eng_seq_id           INTEGER NOT NULL REFERENCES qc_eng_seqs(id),
       qc_seq_project_well_id  INTEGER NOT NULL REFERENCES qc_seq_project_wells(id),
       score                   INTEGER NOT NULL DEFAULT 0,
       pass                    BOOLEAN NOT NULL DEFAULT FALSE,
       UNIQUE(qc_run_id, qc_eng_seq_id, qc_seq_project_well_id)
);
GRANT SELECT ON qc_test_results TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_test_results TO "lims2_staging_rw";
GRANT USAGE ON SEQUENCE qc_test_results_id_seq TO "lims2_staging_rw";

CREATE TABLE qc_alignments (
       id                          SERIAL PRIMARY KEY,
       qc_seq_read_id              TEXT NOT NULL REFERENCES qc_seq_reads(id),
       qc_eng_seq_id               INTEGER NOT NULL REFERENCES qc_eng_seqs(id),
       primer_name                 TEXT NOT NULL,
       query_start                 INTEGER NOT NULL,
       query_end                   INTEGER NOT NULL,
       query_strand                INTEGER NOT NULL CHECK (query_strand IN (1, -1)),
       target_start                INTEGER NOT NULL,
       target_end                  INTEGER NOT NULL,
       target_strand               INTEGER NOT NULL CHECK (target_strand IN (1, -1)),
       score                       INTEGER NOT NULL,
       pass                        BOOLEAN NOT NULL DEFAULT FALSE,
       features                    TEXT NOT NULL,
       cigar                       TEXT NOT NULL,
       op_str                      TEXT NOT NULL
);
GRANT SELECT ON qc_alignments TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_alignments TO "lims2_staging_rw";
GRANT USAGE ON SEQUENCE qc_alignments_id_seq TO "lims2_staging_rw";

CREATE TABLE qc_alignment_regions (
       qc_alignment_id     INTEGER NOT NULL REFERENCES qc_alignments(id),
       name                TEXT NOT NULL,
       length              INTEGER NOT NULL,
       match_count         INTEGER NOT NULL,
       query_str           TEXT NOT NULL,
       target_str          TEXT NOT NULL,
       match_str           TEXT NOT NULL,
       pass                BOOLEAN NOT NULL DEFAULT FALSE,
       PRIMARY KEY(qc_alignment_id, name)
);
GRANT SELECT ON qc_alignment_regions TO "lims2_staging_ro";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_alignment_regions TO "lims2_staging_rw";
