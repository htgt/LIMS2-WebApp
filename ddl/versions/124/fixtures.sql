INSERT INTO schema_versions(version) VALUES (124);

INSERT INTO miseq_classification VALUES ('Not Called');
INSERT INTO miseq_classification VALUES ('Wild Type');
INSERT INTO miseq_classification VALUES ('Het');
INSERT INTO miseq_classification VALUES ('Hom - 1 Allele');
INSERT INTO miseq_classification VALUES ('Hom - 2 Allele');
INSERT INTO miseq_classification VALUES ('Mixed');


INSERT INTO miseq_status VALUES ('Plated');
INSERT INTO miseq_status VALUES ('Scanned-Out');
INSERT INTO miseq_status VALUES ('Empty');

INSERT INTO miseq_projects(name) VALUES ('Miseq_001');
INSERT INTO miseq_projects(name) VALUES ('Miseq_004');
