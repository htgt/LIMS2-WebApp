ALTER TABLE experiments ADD COLUMN plated BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE experiments ADD CONSTRAINT unique_exp_crispr_design UNIQUE  (design_id,crispr_id,crispr_pair_id,crispr_group_id);
