INSERT INTO schema_versions(version) VALUES(135);

UPDATE design_types SET id = 'miseq-nhej' where id = 'miseq';
INSERT INTO design_types(id) VALUES('miseq-hdr');

