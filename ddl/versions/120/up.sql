insert into plate_types values('CRISPR_SEP','Crispr Second Electroporation','allele');
insert into plate_types values('S_PIQ','Second Allele Pre-injection QC plate','allele');
insert into process_types values('crispr_sep','Crispr second electroporation');

alter table crispr_es_qc_runs add column allele_number INT;
alter table audit.crispr_es_qc_runs add column allele_number INT;