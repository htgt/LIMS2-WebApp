INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('ko_first','conditional');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('ko_first','artificial-intron');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('ko_first','intron-replacement');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('deletion','deletion');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('insertion','insertion');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('cre_knock_in','conditional');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('cre_knock_in','artificial-intron');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('cre_knock_in','intron-replacement');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('cre_knock_in','deletion');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('cre_knock_in','insertion');
INSERT INTO mutation_design_types (mutation_id, design_type) VALUES ('cre_knock_in','cre-bac');

UPDATE cassettes SET resistance = 'blastR' WHERE name IN('L1L2_GT0_LacZ_BSD','L1L2_GT1_LacZ_BSD','L1L2_GT2_LacZ_BSD','L1L2_GTK_LacZ_BSD');

INSERT INTO process_types (id, description) VALUES ('xep_pool', 'Pool multiple EP_PICK wells into an XEP well');

INSERT INTO schema_versions(version) VALUES (27);
