ALTER TABLE summaries ADD COLUMN crispr_ep_colonies_rem_unstained INT;
ALTER TABLE summaries ADD COLUMN crispr_ep_colonies_total INT;
ALTER TABLE summaries ADD COLUMN crispr_ep_colonies_picked INT;
ALTER TABLE summaries ADD COLUMN crispr_ep_well_project_id INT;
ALTER TABLE summaries ADD COLUMN crispr_ep_well_project_sponsors TEXT;
ALTER TABLE summaries ADD COLUMN ep_pick_well_crispr_es_qc_well_id INT;
ALTER TABLE summaries ADD COLUMN ep_pick_well_crispr_es_qc_well_call TEXT;
ALTER TABLE summaries ADD COLUMN piq_crispr_es_qc_well_id INT;
ALTER TABLE summaries ADD COLUMN piq_crispr_es_qc_well_call TEXT;
