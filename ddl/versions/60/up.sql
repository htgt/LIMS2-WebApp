ALTER TABLE designs ADD COLUMN global_arm_shortened INTEGER;

CREATE TABLE process_global_arm_shortening_design (
       process_id      INTEGER PRIMARY KEY REFERENCES processes(id),
       design_id       INTEGER NOT NULL REFERENCES designs(id)
);
