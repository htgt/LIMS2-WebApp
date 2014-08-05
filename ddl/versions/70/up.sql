CREATE TABLE crispr_groups (
    id                SERIAL PRIMARY key,
    gene_id           TEXT NOT NULL,
    gene_type_id      TEXT REFERENCES gene_types(id)
);

CREATE TABLE crispr_group_crisprs (
    crispr_group_id      INTEGER NOT NULL REFERENCES crispr_groups(id),
    crispr_id            INTEGER NOT NULL REFERENCES crisprs(id),
    PRIMARY KEY(crispr_group_id, crispr_id)
);
