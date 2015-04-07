create table experiments (
	id serial primary key,
    project_id integer not null references projects(id),
    design_id integer references designs(id),
    crispr_id integer references crisprs(id),
    crispr_pair_id integer references crispr_pairs(id),
    crispr_group_id integer references crispr_groups(id)
);

ALTER TABLE ONLY experiments
    ADD CONSTRAINT experiment_components_key
    UNIQUE (project_id, design_id, crispr_id, crispr_pair_id, crispr_group_id);
