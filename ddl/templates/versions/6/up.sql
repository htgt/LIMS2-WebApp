CREATE TABLE process_electroporation (
       process_id      INTEGER PRIMARY KEY REFERENCES processes(id),
       cell_line       TEXT NOT NULL
);
GRANT SELECT ON process_electroporation TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON process_electroporation TO "[% rw_role %]";

CREATE TABLE picked_colony_types (
       id TEXT PRIMARY KEY
);
GRANT SELECT ON picked_colony_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON picked_colony_types TO "[% rw_role %]";

CREATE TABLE well_colony_picks (
       well_id                INTEGER NOT NULL REFERENCES wells(id),
       colony_type_id         TEXT NOT NULL REFERENCES colony_types(id),
       count                  INTEGER NOT NULL,
       created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
       created_by_id          INTEGER NOT NULL REFERENCES users(id),
       PRIMARY KEY(well_id, colony_type_id)
);
GRANT SELECT ON well_colony_picks TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_colony_picks TO "[% rw_role %]";

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
