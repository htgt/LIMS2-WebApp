ALTER TABLE plate_types ADD COLUMN eng_seq_stage TEXT;

-- disable audit triggers on gene_design table
ALTER TABLE plate_types DISABLE TRIGGER plate_types_audit;

UPDATE plate_types set eng_seq_stage = 'vector' where id = 'INT';
UPDATE plate_types set eng_seq_stage = 'vector' where id = 'POSTINT';
UPDATE plate_types set eng_seq_stage = 'vector' where id = 'FINAL';
UPDATE plate_types set eng_seq_stage = 'vector' where id = 'ASSEMBLY';
UPDATE plate_types set eng_seq_stage = 'vector' where id = 'CRISPR_V';
UPDATE plate_types set eng_seq_stage = 'vector' where id = 'FINAL_PICK';
UPDATE plate_types set eng_seq_stage = 'vector' where id = 'DNA';
UPDATE plate_types set eng_seq_stage = 'vector' where id = 'CREBAC';

UPDATE plate_types set eng_seq_stage = 'allele' where id = 'CRISPR_EP';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'EP';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'EP_PICK';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'XEP';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'XEP_PICK';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'XEP_POOL';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'SEP';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'SEP_PICK';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'SEP_POOL';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'FP';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'SFP';
UPDATE plate_types set eng_seq_stage = 'allele' where id = 'PIQ';

-- enable trigger
ALTER TABLE plate_types ENABLE TRIGGER plate_types_audit;
