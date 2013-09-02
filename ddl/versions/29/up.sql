ALTER TABLE qc_alignments ADD COLUMN qc_run_id character(36) REFERENCES qc_runs (id);
