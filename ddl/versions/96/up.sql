CREATE TABLE crispr_validation(
    id SERIAL PRIMARY KEY,
    crispr_id INT NOT NULL REFERENCES crisprs(id),
    crispr_es_qc_well_id INT NOT NULL REFERENCES crispr_es_qc_wells(id),
    validated BOOLEAN NOT NULL default false
);
