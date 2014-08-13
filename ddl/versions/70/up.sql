CREATE TABLE crispr_groups (
    id                SERIAL PRIMARY key,
    gene_id           TEXT NOT NULL,
    gene_type_id      TEXT REFERENCES gene_types(id)
);

CREATE TABLE crispr_group_crisprs (
    crispr_group_id      INTEGER NOT NULL REFERENCES crispr_groups(id),
    crispr_id            INTEGER NOT NULL REFERENCES crisprs(id),
    left_of_target       BOOLEAN NOT NULL,
    PRIMARY KEY(crispr_group_id, crispr_id)
);

ALTER TABLE crispr_primers ADD COLUMN crispr_group_id INTEGER REFERENCES crispr_groups(id);
ALTER TABLE crispr_primers ADD CONSTRAINT "crispr_group_id and and primer_name must be unique" UNIQUE (crispr_group_id,primer_name);

