CREATE TABLE crispr_damage_types (
    id                TEXT PRIMARY KEY NOT NULL,
    description       TEXT
);

ALTER TABLE crispr_es_qc_wells ADD COLUMN crispr_damage_type_id TEXT REFERENCES crispr_damage_types(id);
