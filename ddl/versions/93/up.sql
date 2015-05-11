-- delete all the crispr_off_target records
DELETE FROM crispr_off_targets;

-- modify crispr_off_target table to new layout
ALTER TABLE crispr_off_targets 
    DROP COLUMN crispr_loci_type_id,
    DROP COLUMN assembly_id,
    DROP COLUMN build_id,
    DROP COLUMN chr_start,
    DROP COLUMN chr_end,
    DROP COLUMN chr_strand,
    DROP COLUMN chromosome,
    DROP COLUMN algorithm;

ALTER TABLE crispr_off_targets ADD COLUMN off_target_crispr_id INTEGER NOT NULL REFERENCES crisprs(id);
ALTER TABLE crispr_off_targets ADD COLUMN mismatches INTEGER NOT NULL;

-- check to make sure we don't add same ot to crispr
ALTER TABLE crispr_off_targets ADD CONSTRAINT unique_crispr_off_target UNIQUE ( crispr_id, off_target_crispr_id );

-- change algorithm from bwa to exhastive in crispr_off_target_summaries table
-- if the crispr has a wge_crispr_id
UPDATE crispr_off_target_summaries SET algorithm = 'exhaustive'
WHERE id IN
(
    SELECT cs.id
    FROM crispr_off_target_summaries cs INNER JOIN crisprs c
    ON c.id = cs.crispr_id
    WHERE cs.algorithm = 'bwa' 
    AND c.wge_crispr_id is NOT NULL
);
