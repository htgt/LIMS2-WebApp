-- Forces a particular crispr/design to have a particular index in the trivial rankings
CREATE TABLE trivial_backfill
(
    id        SERIAL PRIMARY KEY,
    gene_id   TEXT NOT NULL,
    crispr_id INT NOT NULL,
    design_id INT,
    index     INT NOT NULL
);

-- Offsets the indexes where they already exist starting from >1
-- Also can be used to "start" the indexing from 0 where there's a single pair or group
-- which logically ought to go first but has been excluded
CREATE TABLE trivial_offset(
    id           SERIAL PRIMARY KEY,
    gene_id      TEXT NOT NULL,
    crispr_id    INT,
    index_offset INT NOT NULL
);

CREATE UNIQUE INDEX trivial_backfill_combo ON trivial_backfill (gene_id, crispr_id, COALESCE(design_id, -1));
CREATE UNIQUE INDEX trivial_offset_combo ON trivial_offset (gene_id, COALESCE(crispr_id, -1));

-- The trivial view gives index numbers to CRISPRs within genes,
-- to designs within CRISPRs, and to experiments within designs.
-- This allows experiments to be given simple, easy-to-use names that labs can use.
-- It also can be manipulated to support preexisting trivial names using the
-- trivial_backfill and trivial_offset tables.
CREATE VIEW trivial AS
    WITH exp AS (
        SELECT experiments.gene_id,
            Coalesce(experiments.crispr_id, crispr_pair_id, crispr_group_id) AS crispr,
            experiments.design_id, experiments.id AS experiment_id,
            Coalesce(crispr_offset.index_offset, 0) AS crispr_offset, 
            Coalesce(design_offset.index_offset, 0) AS design_offset,
            crispr_backfill.index AS crispr_index,
            design_backfill.index AS design_index
        FROM experiments
        LEFT JOIN trivial_backfill AS crispr_backfill
            ON crispr_backfill.gene_id = experiments.gene_id
            AND crispr_backfill.crispr_id = experiments.crispr_id
            AND crispr_backfill.design_id IS NULL
        LEFT JOIN trivial_backfill AS design_backfill
            ON design_backfill.gene_id = experiments.gene_id
            AND design_backfill.crispr_id = experiments.crispr_id
            AND design_backfill.design_id = experiments.design_id
        LEFT JOIN trivial_offset AS crispr_offset
            ON crispr_offset.gene_id = experiments.gene_id
            AND crispr_offset.crispr_id IS NULL
        LEFT JOIN trivial_offset AS design_offset
            ON design_offset.gene_id = experiments.gene_id
            AND design_offset.crispr_id = experiments.crispr_id
            AND experiments.design_id IS NOT NULL
    ),
    trivial_crispr AS (
        SELECT gene_id, crispr,
            row_number() OVER (PARTITION BY gene_id 
                ORDER BY crispr_index NULLS LAST, min(experiment_id)
            ) + crispr_offset AS trivial_crispr
        FROM exp
        GROUP BY gene_id, crispr, crispr_offset, crispr_index
    ),
    trivial_design AS (
        SELECT gene_id, crispr, design_id,
            row_number() OVER (PARTITION BY gene_id, crispr 
                ORDER BY design_index NULLS LAST, min(experiment_id)
            ) + design_offset AS trivial_design
        FROM exp
        GROUP BY gene_id, crispr, design_id, design_offset, design_index)
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
