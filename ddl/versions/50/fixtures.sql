INSERT INTO schema_versions(version) VALUES (50);
UPDATE well_primer_bands SET pass = 'pass' WHERE pass = 'true';
