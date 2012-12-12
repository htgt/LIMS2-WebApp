CREATE TABLE well_targeting_puro_pass (
       well_id integer NOT NULL REFERENCES wells(id),
       result TEXT NOT NULL,
       created_at timestamp without time zone NOT NULL DEFAULT now(),
       created_by_id integer NOT NULL REFERENCES users(id),
       PRIMARY KEY(well_id)
);
GRANT SELECT ON well_targeting_puro_pass TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_targeting_puro_pass TO "[% rw_role %]";

