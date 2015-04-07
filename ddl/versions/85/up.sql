CREATE TABLE crispr_tracker_rnas (
       id integer NOT NULL,
       name TEXT NOT NULL,
       PRIMARY KEY(id)
);

CREATE TABLE process_crispr_tracker_rna (
       process_id integer NOT NULL REFERENCES processes(id),
       crispr_tracker_rna_id integer NOT NULL REFERENCES crispr_tracker_rnas(id),
       PRIMARY KEY(process_id)
);
