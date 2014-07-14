ALTER TABLE audit.designs ALTER COLUMN design_parameters TYPE json USING design_parameters::JSON;
ALTER TABLE audit.crispr_es_qc_wells ALTER COLUMN analysis_data TYPE json USING analysis_data::JSON;
