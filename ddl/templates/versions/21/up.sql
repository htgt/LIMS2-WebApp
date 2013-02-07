CREATE TABLE project_information (
       project_id          INTEGER PRIMARY KEY REFERENCES projects (id),
       gene_id             TEXT,
       targeting_type      TEXT NOT NULL
);
GRANT SELECT ON project_information TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON project_information TO "[% rw_role %]";

CREATE TABLE cassette_function (
       id            TEXT PRIMARY KEY,
       promoter      BOOL,
       conditional   BOOL,
       cre           BOOL,
       well_has_cre  BOOL,
       well_has_no_recombinase  BOOL
);
GRANT SELECT ON cassette_function TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON cassette_function TO "[% rw_role %]";

CREATE TABLE project_alleles (
       project_id          INTEGER REFERENCES projects (id),
       allele_type                TEXT NOT NULL,
       cassette_function   TEXT NOT NULL REFERENCES cassette_function(id),
       mutation_type       TEXT NOT NULL,
       PRIMARY KEY (project_id, allele_type)
);
GRANT SELECT ON project_alleles TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON project_alleles TO "[% rw_role %]";

