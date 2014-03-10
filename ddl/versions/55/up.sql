CREATE TABLE nucleases (
       id integer NOT NULL,
       name TEXT NOT NULL,
       PRIMARY KEY(id)
);

CREATE TABLE process_nuclease (
       process_id integer NOT NULL REFERENCES processes(id),
       nuclease_id integer NOT NULL REFERENCES nucleases(id),
       PRIMARY KEY(process_id)
);