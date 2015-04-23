CREATE TABLE oxygen_conditions (
       id integer NOT NULL,
       name TEXT NOT NULL,
       PRIMARY KEY(id)
);

CREATE TABLE process_oxygen_condition (
       process_id integer NOT NULL REFERENCES processes(id),
       oxygen_condition_id integer NOT NULL REFERENCES oxygen_conditions(id),
       PRIMARY KEY(process_id)
);

CREATE TABLE process_doublings(
       process_id integer NOT NULL REFERENCES processes(id),
       doublings integer NOT NULL,
       PRIMARY KEY(process_id)
);