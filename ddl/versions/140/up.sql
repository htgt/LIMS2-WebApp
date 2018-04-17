DROP VIEW IF EXISTS trivial;
DROP TABLE IF EXISTS trivial_backfill;
DROP TABLE IF EXISTS trivial_offset;
-- Offsets the indexes where they already exist
CREATE TABLE trivial_offset(
    gene_id      TEXT PRIMARY KEY NOT NULL,
    crispr_offset INT NOT NULL
);
ALTER TABLE experiments ADD assigned_trivial text;

CREATE VIEW trivial AS
    WITH exp AS (
        SELECT experiments.gene_id,
            Coalesce(experiments.crispr_id, crispr_pair_id, crispr_group_id) AS crispr,
            experiments.design_id, experiments.id AS experiment_id,
            Coalesce(trivial_offset.crispr_offset, 0) AS crispr_offset
        FROM experiments
        LEFT JOIN trivial_offset
            ON trivial_offset.gene_id = experiments.gene_id
        -- ignore experiments with assigned trivial names for calculate the index on calculated trivials.
        -- if another experiment with the same CRISPR is added, it will get a new index based on that.
        WHERE assigned_trivial IS NULL
    ),
    -- rank crisprs, incorporating the offset
    trivial_crispr AS (
        SELECT gene_id, crispr,
            row_number() OVER (PARTITION BY gene_id ORDER BY min(experiment_id)) 
                + crispr_offset AS trivial_crispr
        FROM exp
        GROUP BY gene_id, crispr, crispr_offset
    ),
    -- rank designs
    trivial_design AS (
        SELECT gene_id, crispr, design_id,
            row_number() OVER (PARTITION BY gene_id, crispr ORDER BY min(experiment_id))
            AS trivial_design
        FROM exp
        GROUP BY gene_id, crispr, design_id
    )
    -- use the earlier subqueries, and add the experiment rank
    SELECT species_id, experiment_id, exp.gene_id, exp.crispr, trivial_crispr, 
        exp.design_id, trivial_design,
        dense_rank() OVER (PARTITION BY exp.gene_id, exp.crispr, exp.design_id ORDER BY experiment_id)
            AS trivial_experiment
        FROM exp
        LEFT JOIN designs ON designs.id = exp.design_id 
        INNER JOIN trivial_crispr
            ON trivial_crispr.gene_id = exp.gene_id
            AND trivial_crispr.crispr = exp.crispr
        INNER JOIN trivial_design 
            ON trivial_design.gene_id = exp.gene_id
            AND trivial_design.crispr = exp.crispr
            AND trivial_design.design_id = exp.design_id
        ORDER BY exp.gene_id, exp.crispr, exp.design_id, experiment_id;
