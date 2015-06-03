CREATE TYPE qc_element_type AS ENUM ('Good', 'Bad', 'Wrong');
CREATE TYPE assembly_well_qc_type AS ENUM ('CRISPR_LEFT_QC', 'CRISPR_RIGHT_QC', 'VECTOR_QC' );

CREATE TABLE well_assembly_qc(
        id               SERIAL PRIMARY KEY,
        assembly_well_id INT not null REFERENCES wells(id),
        qc_type          assembly_well_qc_type not null,
        value            qc_element_type not null,
        unique (assembly_well_id, qc_type)
);
