CREATE TABLE well_targeting_neo_pass (
       well_id integer NOT NULL REFERENCES wells(id),
       result TEXT NOT NULL,
       created_at timestamp without time zone NOT NULL DEFAULT now(),
       created_by_id integer NOT NULL REFERENCES users(id),
       PRIMARY KEY(well_id)
);
