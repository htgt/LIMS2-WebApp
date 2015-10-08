CREATE TABLE sequencing_projects(
    id serial primary key not null,
    name text not null,
    qc_template_id integer references qc_templates(id),
    created_by_id integer references users(id) not null,
    created_at timestamp without time zone default now() not null,
    sub_projects integer not null,
    qc boolean default false,
    available_results boolean default false,
    abandoned boolean default false, 
    is_384 boolean default false);

CREATE TABLE sequencing_primer_types( id text primary key not null );

CREATE TABLE sequencing_project_primers(
    seq_project_id integer references sequencing_projects(id) not null,
    primer_id text references sequencing_primer_types(id) not null);

CREATE TABLE sequencing_project_templates(
    seq_project_id integer references sequencing_projects(id) not null,
    qc_template_id integer references qc_templates(id) not null);
