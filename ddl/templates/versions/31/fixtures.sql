INSERT INTO crispr_loci_types(id) VALUES ('Exonic'), ('Intronic'), ('Intergenic');
INSERT INTO schema_versions(version) VALUES (31);
INSERT INTO plate_types(id, description) VALUES ('CRISPR', 'Crispr Plate');
INSERT INTO process_types ( id, description  ) VALUES ( 'create_crispr', 'Create crispr' );
