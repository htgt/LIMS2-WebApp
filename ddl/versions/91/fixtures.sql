insert into plate_types(id,description,eng_seq_stage) values
('CGAP_QC','QC of samples returned from CGAP','allele'),
('MS_QC','QC of samples during Mutation Signatures workflow','allele');

insert into process_types(id,description) values
('cgap_qc','QC of samples returned from CGAP'),
('ms_qc','QC of samples during Mutation Signatures workflow');

INSERT INTO schema_versions(version) VALUES (90);