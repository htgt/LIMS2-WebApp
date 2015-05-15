CREATE TYPE qc_element_type AS ENUM ('Good', 'Bad', 'Wrong');

CREATE TABLE assembly_well_qc_types(
    id SERIAL PRIMARY KEY,
    qc_type TEXT
    
);

CREATE TABLE well_assembly_qc(
        id SERIAL PRIMARY KEY,
        assembly_well_id not null REFERENCES wells(id),    
        qc_type not null REFERENCES assembly_well_qc_types(qc_type),
        value not null qc_element_type
);
