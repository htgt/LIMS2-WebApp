ALTER TABLE qc_seq_reads
DROP COLUMN qc_seq_project_well_id;

ALTER TABLE qc_seq_reads
ADD COLUMN qc_seq_project_id TEXT NOT NULL REFERENCES qc_seq_projects(id);

ALTER TABLE qc_test_results
DROP COLUMN qc_seq_project_well_id;

DROP TABLE qc_seq_project_qc_seq_project_well CASCADE;

DROP TABLE qc_seq_project_wells CASCADE;

CREATE TABLE qc_run_seq_wells (
       id                     SERIAL PRIMARY KEY,
       qc_run_id              TEXT NOT NULL REFERENCES qc_runs(id),
       plate_name             TEXT NOT NULL,
       well_name              TEXT NOT NULL,
       UNIQUE(qc_run_id, plate_name, well_name) 
);
GRANT SELECT ON qc_run_seq_wells TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_run_seq_wells TO "[% rw_role %]";
GRANT USAGE ON qc_run_seq_wells_id_seq TO "[% rw_role %]";

CREATE TABLE qc_run_seq_well_qc_seq_read (
       qc_run_seq_well_id  INTEGER NOT NULL REFERENCES qc_run_seq_wells(id),
       qc_seq_read_id      TEXT NOT NULL REFERENCES qc_seq_reads(id)
);
GRANT SELECT ON qc_run_seq_well_qc_seq_read TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_run_seq_well_qc_seq_read TO "[% rw_role %]";

ALTER TABLE qc_test_results
ADD COLUMN qc_run_seq_well_id INTEGER NOT NULL REFERENCES qc_run_seq_wells(id);

