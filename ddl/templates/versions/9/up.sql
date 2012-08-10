ALTER TABLE cassettes ADD COLUMN conditional BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE sponsors (
       id          TEXT PRIMARY KEY,
       description TEXT NOT NULL DEFAULT ''
);
GRANT SELECT ON sponsors TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON sponsors TO "[% rw_role %]";

CREATE TABLE projects (
       id             SERIAL PRIMARY KEY,
       sponsor_id     TEXT NOT NULL REFERENCES sponsors(id),
       allele_request TEXT NOT NULL
);
GRANT SELECT ON projects TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON projects TO "[% rw_role %]";
GRANT USAGE ON projects_id_seq TO "[% rw_role %]";

ALTER TABLE process_output_well ADD UNIQUE(well_id);
