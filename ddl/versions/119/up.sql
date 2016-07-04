CREATE TABLE sequencing_project_backups (
    seq_project_id integer REFERENCES sequencing_projects(id) NOT NULL,
    directory text NOT NULL,
    creation_date timestamp without time zone default now() NOT NULL,
    PRIMARY KEY(seq_project_id, directory)
);
