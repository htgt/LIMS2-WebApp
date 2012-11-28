CREATE TABLE genotyping_result_types (
       id  TEXT NOT NULL, 
       PRIMARY KEY(id)
);
GRANT SELECT ON genotyping_result_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON genotyping_result_types TO "[% rw_role %]";

CREATE TABLE well_genotyping_results (
       well_id                    INTEGER NOT NULL REFERENCES wells(id),
       genotyping_result_type_id  TEXT NOT NULL REFERENCES genotyping_result_types(id),
       call                       TEXT NOT NULL,
       copy_number                FLOAT,
       copy_number_range          FLOAT,
       confidence                 FLOAT,
       created_at                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id              INTEGER NOT NULL REFERENCES users(id),
       PRIMARY KEY(well_id, genotyping_result_type_id)
);
GRANT SELECT ON well_genotyping_results TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_genotyping_results TO "[% rw_role %]";
