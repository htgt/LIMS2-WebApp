ALTER TABLE design_targets RENAME COLUMN gene_name TO marker_symbol;
ALTER TABLE design_targets ALTER COLUMN marker_symbol DROP NOT NULL;
ALTER TABLE design_targets ADD COLUMN gene_id TEXT;
ALTER TABLE design_targets ADD CONSTRAINT design_targets_unique_target UNIQUE (ensembl_exon_id, build_id);
