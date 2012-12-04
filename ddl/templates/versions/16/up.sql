CREATE TABLE qc_template_well_cassette (
       qc_template_well_id          INTEGER PRIMARY KEY REFERENCES qc_template_wells (id),
       cassette_id                  INTEGER NOT NULL REFERENCES cassettes (id)
);
GRANT SELECT ON qc_template_well_cassette TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_template_well_cassette TO "[% rw_role %]";

CREATE TABLE qc_template_well_backbone (
       qc_template_well_id          INTEGER PRIMARY KEY REFERENCES qc_template_wells (id),
       backbone_id                  INTEGER NOT NULL REFERENCES backbones (id)
);
GRANT SELECT ON qc_template_well_backbone TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_template_well_backbone TO "[% rw_role %]";

CREATE TABLE qc_template_well_recombinase (
       qc_template_well_id          INTEGER NOT NULL REFERENCES qc_template_wells (id),
       recombinase_id               TEXT NOT NULL REFERENCES recombinases (id),
       PRIMARY KEY(qc_template_well_id,recombinase_id)
);
GRANT SELECT ON qc_template_well_recombinase TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON qc_template_well_recombinase TO "[% rw_role %]";
