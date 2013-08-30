ALTER TABLE crispr_off_targets ADD algorithm TEXT;
UPDATE crispr_off_targets set algorithm = 'strict';
-- can only set column to NOT NULL once I have filled in data
ALTER TABLE crispr_off_targets ALTER COLUMN algorithm SET NOT NULL;

CREATE TABLE crispr_off_target_summaries (
    id                    SERIAL PRIMARY KEY,
    crispr_id             INTEGER NOT NULL REFERENCES crisprs(id),
    outlier               BOOL NOT NULL,
    algorithm             TEXT NOT NULL,
    summary               TEXT
);
GRANT SELECT ON crispr_off_target_summaries TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON crispr_off_target_summaries TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE crispr_off_target_summaries_id_seq TO "[% rw_role %]";

ALTER TABLE crisprs DISABLE TRIGGER crisprs_audit;
-- migrate data 
INSERT INTO crispr_off_target_summaries ( crispr_id, outlier, algorithm, summary )
SELECT id, off_target_outlier, 'strict', comment
from crisprs;

ALTER TABLE crisprs DROP off_target_outlier;
UPDATE crisprs set comment = NULL;

ALTER TABLE crisprs ENABLE TRIGGER crisprs_audit;
