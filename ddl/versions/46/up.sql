--to store paired crispr information
CREATE TABLE crispr_pairs (
    id                  SERIAL PRIMARY key,
    left_crispr         INTEGER NOT NULL REFERENCES crisprs(id),
    right_crispr        INTEGER NOT NULL REFERENCES crisprs(id),
    spacer              INTEGER NOT NULL,
    off_target_summary  TEXT
);

--we need a way to allow a user to link a crispr to a design
CREATE TABLE crispr_designs (
    id                SERIAL PRIMARY KEY,
    crispr_id         INTEGER REFERENCES crisprs(id),
    crispr_pair_id    INTEGER REFERENCES crispr_pairs(id),
    design_id         INTEGER NOT NULL REFERENCES designs(id),
    plated            BOOL NOT NULL DEFAULT false
);

--this is to make searching for pairs easier
ALTER TABLE crisprs ADD pam_right BOOL;
