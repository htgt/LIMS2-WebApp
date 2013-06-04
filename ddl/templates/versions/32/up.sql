ALTER TABLE crispr_off_targets DROP CONSTRAINT IF EXISTS crispr_off_targets_chr_id_fkey;

ALTER TABLE crispr_off_targets ADD chromosome TEXT;

-- migrate data to new chromosome column
UPDATE crispr_off_targets set chromosome = chromosomes.name
FROM chromosomes where chromosomes.id = crispr_off_targets.chr_id;

ALTER TABLE crispr_off_targets DROP chr_id;
