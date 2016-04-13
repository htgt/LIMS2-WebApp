ALTER TABLE audit.qc_run_seq_project ADD COLUMN sequencing_data_version text;
ALTER TABLE audit.crispr_es_qc_runs ADD COLUMN sequencing_data_version text;
