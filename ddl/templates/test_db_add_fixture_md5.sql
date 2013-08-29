CREATE TABLE fixture_md5 (
       md5         TEXT NOT NULL,
       created_at  TIMESTAMP NOT NULL
);
GRANT SELECT ON fixture_md5 TO "[% ro_role %]";
-- 18/6/2013 LGE: Complaints: "ERROR:  invalid privilege type USAGE for table" 
-- GRANT USAGE ON fixture_md5 TO "[% rw_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON fixture_md5 TO "[% rw_role %]";
