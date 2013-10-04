CREATE INDEX summaries_ep_pick_well_id_index    ON summaries USING btree (ep_pick_well_id);
CREATE INDEX summaries_sep_pick_well_id_index   ON summaries USING btree (sep_pick_well_id);
CREATE INDEX summaries_design_gene_id_index     ON summaries USING btree (design_gene_id);
CREATE INDEX summaries_design_gene_symbol_index ON summaries USING btree (design_gene_symbol);