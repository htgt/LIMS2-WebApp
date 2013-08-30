CREATE TABLE well_lab_number
(
  well_id                         INTEGER NOT NULL,
  lab_number                      TEXT NOT NULL,
  CONSTRAINT well_lab_number_pkey PRIMARY KEY (well_id),
  CONSTRAINT lab_number_unique UNIQUE(lab_number),
  CONSTRAINT well_lab_number_well_id_fkey FOREIGN KEY (well_id)
      REFERENCES wells (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
GRANT SELECT ON well_lab_number TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON well_lab_number TO "[% rw_role %]";