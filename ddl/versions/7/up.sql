CREATE TABLE process_cell_line (
       process_id      INTEGER PRIMARY KEY REFERENCES processes(id),
       cell_line       TEXT NOT NULL
);
GRANT SELECT ON process_cell_line TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_cell_line TO "[% rw_role %]";

CREATE TABLE colony_count_types (
       id TEXT PRIMARY KEY
);
GRANT SELECT ON colony_count_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON colony_count_types TO "[% rw_role %]";

CREATE TABLE well_colony_counts (
       well_id                INTEGER NOT NULL REFERENCES wells(id),
       colony_count_type_id   TEXT NOT NULL REFERENCES colony_count_types(id),
       colony_count           INTEGER NOT NULL,
       created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id          INTEGER NOT NULL REFERENCES users(id),
       PRIMARY KEY(well_id, colony_count_type_id)
);
GRANT SELECT ON well_colony_counts TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_colony_counts TO "[% rw_role %]";

CREATE TABLE primer_band_types (
       id TEXT PRIMARY KEY
);
GRANT SELECT ON primer_band_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON primer_band_types TO "[% rw_role %]";

CREATE TABLE well_primer_bands (
       well_id                 INTEGER NOT NULL REFERENCES wells(id),
       primer_band_type_id     TEXT NOT NULL REFERENCES primer_band_types(id),
       pass                    BOOLEAN DEFAULT TRUE,
       created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id           INTEGER NOT NULL REFERENCES users(id),
       PRIMARY KEY(well_id, primer_band_type_id)
);
GRANT SELECT ON well_primer_bands TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_primer_bands TO "[% rw_role %]";
