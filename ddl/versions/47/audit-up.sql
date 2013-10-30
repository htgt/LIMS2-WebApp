ALTER TABLE audit.crispr_pairs ADD COLUMN left_crispr_id integer;
ALTER TABLE audit.crispr_pairs ADD COLUMN right_crispr_id integer;
ALTER TABLE audit.crispr_pairs DROP COLUMN right_crispr;
ALTER TABLE audit.crispr_pairs DROP COLUMN left_crispr;
