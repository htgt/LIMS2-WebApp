ALTER TABLE crispr_es_qc_wells ADD COLUMN variant_size INT;
ALTER TABLE crispr_es_qc_runs ADD COLUMN validated BOOLEAN DEFAULT FALSE;
