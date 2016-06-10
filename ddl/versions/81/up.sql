alter table crispr_primers ADD COLUMN is_validated BOOLEAN;
alter table crispr_primers ADD COLUMN is_rejected BOOLEAN;

alter table genotyping_primers ADD COLUMN is_validated BOOLEAN;
alter table genotyping_primers ADD COLUMN is_rejected BOOLEAN;

create table qc_template_well_crispr_primers (
    qc_run_id bpchar REFERENCES qc_runs(id),
    qc_template_well_id INT REFERENCES qc_template_wells(id),
    crispr_primer_id INT REFERENCES crispr_primers(crispr_oligo_id),
    PRIMARY KEY(qc_run_id, qc_template_well_id, crispr_primer_id)
);

create table qc_template_well_genotyping_primers (
    qc_run_id bpchar REFERENCES qc_runs(id),
    qc_template_well_id INT REFERENCES qc_template_wells(id),
    genotyping_primer_id INT REFERENCES genotyping_primers(id),
    PRIMARY KEY(qc_run_id, qc_template_well_id, genotyping_primer_id)
);
