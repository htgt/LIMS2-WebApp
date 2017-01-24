CREATE TABLE miseq_projects (
    id serial primary key NOT NULL,
    name text NOT NULL,
    creation_date timestamp without time zone default now() NOT NULL
);

CREATE TABLE miseq_classification (
    id text primary key NOT NULL
);

CREATE TABLE miseq_status (
    id text primary key NOT NULL
);

CREATE TABLE miseq_project_well (
    miseq_well_id serial primary key NOT NULL,
    miseq_plate_id integer NOT NULL REFERENCES miseq_projects(id),
    illumina_index integer NOT NULL,
    status text REFERENCES miseq_status(id)
);

CREATE TABLE miseq_project_well_exp (
    miseq_well_id integer NOT NULL,
    experiment text NOT NULL,
    classification text REFERENCES miseq_classification(id)
);
