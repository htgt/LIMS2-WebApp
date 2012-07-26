--
-- Schema for sponsors table
--

CREATE TABLE sponsors (
       id          TEXT PRIMARY KEY,
       description TEXT DEFAULT ''
);
GRANT SELECT ON sponsors TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON sponsors TO "[% rw_role %]";
