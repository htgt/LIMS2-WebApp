INSERT INTO schema_versions(version) VALUES (51);
INSERT INTO plate_types (id, description) VALUES ('CRISPR_V', 'Crispr Vectors');
INSERT INTO plate_types (id, description) VALUES ('CRISPR_EP', 'Crispr Electroporation');
INSERT INTO process_types (id, description) VALUES ('crispr_vector', 'Create crispr vector');
INSERT INTO process_types (id, description) VALUES ('crispr_single_ep', 'Single crispr electroporation');
INSERT INTO process_types (id, description) VALUES ('crispr_paired_ep', 'Paired crispr electroporation');
