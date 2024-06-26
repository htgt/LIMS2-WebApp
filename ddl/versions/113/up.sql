ALTER TABLE experiments ADD COLUMN deleted BOOL NOT NULL DEFAULT FALSE;

ALTER TABLE experiments DROP CONSTRAINT unique_exp_crispr_design;
CREATE UNIQUE INDEX design_crispr_combo ON experiments (
	COALESCE(design_id, -1),
	COALESCE(crispr_id,-1),
	COALESCE(crispr_pair_id,-1),
	COALESCE(crispr_group_id,-1)
);

CREATE RULE flag_delete_experiment AS ON DELETE TO experiments DO INSTEAD (UPDATE experiments SET deleted=TRUE where id=OLD.id);
