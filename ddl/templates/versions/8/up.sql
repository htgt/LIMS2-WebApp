--
-- Schema for sponsors table
--

CREATE TABLE sponsors (
       id          TEXT PRIMARY KEY,
       description TEXT DEFAULT ''
);
GRANT SELECT ON sponsors TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON sponsors TO "[% rw_role %]";

-- XXX at the very least, need unique key on mutation_type, targeting_type, cassette_function
-- Should we dispense with the SERIAL id column on these tables?

CREATE TABLE mutation_types (
       id            SERIAL PRIMARY KEY,
       mutation_type TEXT NOT NULL
);
GRANT SELECT ON mutation_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON mutation_types TO "[% rw_role %]";       

CREATE TABLE targeting_types (
       id             SERIAL PRIMARY KEY,
       targeting_type TEXT NOT NULL
);
GRANT SELECT ON targeting_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON targeting_types TO "[% rw_role %]";

CREATE TABLE cassette_functions (
       id                SERIAL PRIMARY KEY,
       cassette_function TEXT NOT NULL
);
GRANT SELECT ON cassette_functions TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON cassette_functions TO "[% rw_role %]";

CREATE TABLE cassette_cassette_functions (
       cassette_id INTEGER NOT NULL REFERENCES cassettes(id),
       function_id INTEGER NOT NULL REFERENCES cassette_functions(id),
       PRIMARY KEY(cassette_id,function_id)
);
GRANT SELECT ON cassette_cassette_functions TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON cassette_cassette_functions TO "[% rw_role %]";
