ALTER TABLE crispr_validation
DROP CONSTRAINT crispr_validation_crispr_es_qc_well_id_fkey,
ADD CONSTRAINT crispr_validation_crispr_es_qc_well_id_fkey
   FOREIGN KEY (crispr_es_qc_well_id)
   REFERENCES crispr_es_qc_wells(id)
   ON DELETE CASCADE;
