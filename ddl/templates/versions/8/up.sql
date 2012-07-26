--
-- Schema for sponsors table
--

CREATE TABLE sponsors (
       id          TEXT PRIMARY KEY,
       description TEXT DEFAULT ''
);
GRANT SELECT ON sponsors TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON sponsors TO "[% rw_role %]";

CREATE TABLE mutation_type (
       id            SERIAL PRIMARY KEY,
       mutation_type TEXT NOT NULL
);
GRANT SELECT ON mutation_type TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON mutation_type TO "[% rw_role %]";       

CREATE TABLE targeting_type (
       id             SERIAL PRIMARY KEY,
       targeting_type TEXT NOT NULL
);
GRANT SELECT ON targeting_type TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON targeting_type TO "[% rw_role %]";

CREATE TABLE final_cassette_function (
       id                      SERIAL PRIMARY KEY,
       final_cassette_function TEXT NOT NULL
);
GRANT SELECT ON final_cassette_function TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON final_cassette_function TO "[% rw_role %]";
