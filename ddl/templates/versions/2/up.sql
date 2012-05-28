
DROP TABLE qc_seq_project_wells CASCADE;

CREATE TABLE qc_seq_project_wells (
   id         SERIAL PRIMARY KEY,   
   plate_name TEXT NOT NULL,
   well_name  TEXT NOT NULL,
   UNIQUE (plate_name, well_name)
);
GRANT SELECT ON qc_seq_project_wells TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_seq_project_wells TO "[% rw_role %]";
GRANT USAGE ON qc_seq_project_wells_id_seq TO  "[% rw_role %]";

CREATE TABLE qc_seq_project_qc_seq_project_well (
   qc_seq_project_id      TEXT NOT NULL REFERENCES qc_seq_projects(id),
   qc_seq_project_well_id INTEGER NOT NULL REFERENCES qc_seq_project_wells(id),
   PRIMARY KEY(qc_seq_project_id, qc_seq_project_well_id)
);
GRANT SELECT ON qc_seq_project_qc_seq_project_well TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_seq_project_qc_seq_project_well TO "[% rw_role %]";

ALTER TABLE qc_test_results
ADD CONSTRAINT "qc_test_results_qc_seq_project_well_id_fkey"
FOREIGN KEY (qc_seq_project_well_id) REFERENCES qc_seq_project_wells(id);

ALTER TABLE qc_seq_reads
ADD CONSTRAINT "qc_seq_reads_qc_seq_project_well_id_fkey"
FOREIGN KEY (qc_seq_project_well_id) REFERENCES qc_seq_project_wells(id);
