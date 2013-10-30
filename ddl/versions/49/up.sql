ALTER TABLE crispr_pairs ADD CONSTRAINT unique_pair UNIQUE(left_crispr_id, right_crispr_id);

ALTER TABLE crispr_designs ADD CONSTRAINT unique_crispr_design UNIQUE(design_id, crispr_id);
ALTER TABLE crispr_designs ADD CONSTRAINT unique_crispr_pair_design UNIQUE(design_id, crispr_pair_id);
