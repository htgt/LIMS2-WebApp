CREATE TABLE audit.qc_template_well_genotyping_primers (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_run_id character(36),
qc_template_well_id integer,
genotyping_primer_id integer
);
CREATE OR REPLACE FUNCTION public.process_qc_template_well_genotyping_primers_audit()
RETURNS TRIGGER AS $qc_template_well_genotyping_primers_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_template_well_genotyping_primers SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_template_well_genotyping_primers SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_template_well_genotyping_primers SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_template_well_genotyping_primers_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_template_well_genotyping_primers_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_template_well_genotyping_primers
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_template_well_genotyping_primers_audit();
ALTER TABLE audit.crispr_primers ADD COLUMN is_validated boolean;
ALTER TABLE audit.crispr_primers ADD COLUMN is_rejected boolean;

ALTER TABLE audit.genotyping_primers ADD COLUMN is_validated boolean;
ALTER TABLE audit.genotyping_primers ADD COLUMN is_rejected boolean;
CREATE TABLE audit.qc_template_well_crispr_primers (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_run_id character(36),
qc_template_well_id integer,
crispr_primer_id integer
);
CREATE OR REPLACE FUNCTION public.process_qc_template_well_crispr_primers_audit()
RETURNS TRIGGER AS $qc_template_well_crispr_primers_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_template_well_crispr_primers SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_template_well_crispr_primers SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_template_well_crispr_primers SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_template_well_crispr_primers_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_template_well_crispr_primers_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_template_well_crispr_primers
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_template_well_crispr_primers_audit();
