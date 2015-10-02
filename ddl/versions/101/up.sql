CREATE TABLE sequencing_projects(
    id serial primary key not null,
    name text not null,
    qc_template_id integer references qc_templates(id) not null,
    created_by_id integer references users(id) not null,
    created_at timestamp without time zone default now() not null,
    sub_projects integer not null,
    qc boolean default false,
    available_results boolean default false,
    abandoned boolean default false, 
    is_384 boolean default false);

CREATE TABLE sequencing_project_crispr_primers(
    seq_project_id integer references sequencing_projects(id) not null,
    primer_id integer references crispr_primer_types(primer_name) not null);

CREATE TABLE sequencing_project_genotyping_primers(
    seq_project_id integer references sequencing_projects(id) not null,
    primer_id integer references genotyping_primer_types(id) not null);
