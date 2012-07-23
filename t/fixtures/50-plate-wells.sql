--
-- Minimal Plate/Well Data
--

INSERT INTO plates(name, type_id, species_id, created_by_id)
SELECT '100', 'DESIGN', 'Mouse', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = '100';

INSERT INTO plates(name, type_id, species_id, created_by_id)
SELECT 'PCS100', 'INT', 'Mouse', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = 'PCS100';

INSERT INTO plates(name, type_id, species_id, created_by_id)
SELECT 'PGS100', 'POSTINT', 'Mouse', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = 'PGS100';

INSERT INTO plates(name, type_id, species_id, created_by_id)
SELECT 'PCS200', 'INT', 'Mouse', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = 'PCS200';

INSERT INTO plates(name, type_id, species_id, created_by_id)
SELECT 'FINAL100', 'FINAL', 'Mouse', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = 'FINAL100';
