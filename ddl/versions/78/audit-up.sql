ALTER TABLE audit.crispr_es_qc_wells ADD COLUMN variant_size INT;
ALTER TABLE audit.crispr_es_qc_runs ADD COLUMN validated BOOLEAN;
