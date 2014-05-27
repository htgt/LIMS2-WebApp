INSERT INTO schema_versions(version) VALUES (65);

UPDATE plates SET sponsor_id = 'EUCOMMTools Recovery' WHERE name LIKE 'ETMR%';
UPDATE plates SET sponsor_id = 'Pathogens' WHERE name LIKE 'PSAB6%';

