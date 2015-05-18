CREATE TYPE qc_element_type AS ENUM ('Good', 'Bad', 'Wrong');
CREATE TYPE assembly_well_qc_type AS ENUM ('CRISPR_LEFT_QC', 'CRISPR_RIGHT_QC', 'VECTOR_QC' );

CREATE TABLE assembly_well_qc_types(
    id SERIAL PRIMARY KEY,
    qc_type TEXT
    
);

CREATE TABLE well_assembly_qc(
        id SERIAL PRIMARY KEY,
        assembly_well_id not null REFERENCES wells(id),    
        qc_type not null assembly_well_qc_type,
        value not null qc_element_type
);
