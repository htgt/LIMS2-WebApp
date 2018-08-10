INSERT INTO schema_versions(version) VALUES (144);

INSERT INTO programmes (id, name) VALUES (1, 'Human Genetics');
INSERT INTO programmes (id, name) VALUES (2, 'Cellular Genetics');
INSERT INTO programmes (id, name) VALUES (3, 'Pathogen and Malaria');
INSERT INTO programmes (id, name) VALUES (4, 'Cancer Ageing and Somatic Mutation');
INSERT INTO programmes (id, name) VALUES (5, 'Other');

INSERT INTO lab_heads (id, name) VALUES (1, 'Matthew Hurles');
INSERT INTO lab_heads (id, name) VALUES (2, 'Nicholas Thomson');
INSERT INTO lab_heads (id, name) VALUES (3, 'Antonio Vidal-Puig');
INSERT INTO lab_heads (id, name) VALUES (4, 'Ludovic Vallier');
INSERT INTO lab_heads (id, name) VALUES (5, 'David Adams');
INSERT INTO lab_heads (id, name) VALUES (6, 'Bob Hancock');
INSERT INTO lab_heads (id, name) VALUES (7, 'Other');

INSERT INTO requesters (id) VALUES ('sc22@sanger.ac.uk');
INSERT INTO requesters (id) VALUES ('meh@sanger.ac.uk');

--ALTER TABLE project_sponsors DISABLE TRIGGER project_sponsors_audit;
--ALTER TABLE project_sponsors ENABLE TRIGGER project_sponsors_audit;

