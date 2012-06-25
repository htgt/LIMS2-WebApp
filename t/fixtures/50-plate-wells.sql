--
-- Minimal Plate/Well Data
--

INSERT INTO plates(name, type_id, created_by_id)
SELECT '100', 'DESIGN', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = '100';

INSERT INTO plates(name, type_id, created_by_id)
SELECT 'PCS100', 'INT', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = 'PCS100';

INSERT INTO plates(name, type_id, created_by_id)
SELECT 'PGS100', 'POSTINT', users.id
FROM users
where users.name = 'test_user@example.org';

INSERT INTO wells(plate_id, name, created_by_id)
SELECT plates.id, 'A01', plates.created_by_id
FROM plates
WHERE plates.name = 'PGS100';
