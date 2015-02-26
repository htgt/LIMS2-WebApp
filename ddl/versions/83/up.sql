ALTER TABLE designs ADD COLUMN nonsense_design_crispr_id INT;
ALTER TABLE designs ADD foreign key (nonsense_design_crispr_id) references crisprs(id);

ALTER TABLE crisprs ADD COLUMN nonsense_crispr_original_crispr_id INT;
ALTER TABLE crisprs ADD foreign key (nonsense_crispr_original_crispr_id) references crisprs(id);

