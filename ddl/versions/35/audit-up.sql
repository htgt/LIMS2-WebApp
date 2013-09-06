ALTER TABLE audit.design_targets RENAME COLUMN gene_name TO marker_symbol;
ALTER TABLE audit.design_targets ADD COLUMN gene_id TEXT;
