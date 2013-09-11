CREATE SEQUENCE designs_id_seq;
ALTER TABLE designs ALTER COLUMN id SET DEFAULT nextval('designs_id_seq');

GRANT USAGE ON SEQUENCE designs_id_seq TO "[% rw_role %]";

SELECT setval('designs_id_seq', 1000000);
