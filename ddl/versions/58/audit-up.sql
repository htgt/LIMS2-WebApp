CREATE TABLE audit.crispr_es_qc_wells (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
crispr_es_qc_run_id character(36),
well_id integer,
fwd_read text,
rev_read text,
crispr_chr_id integer,
crispr_start integer,
crispr_end integer,
comment text,
analysis_data text
);
CREATE OR REPLACE FUNCTION public.process_crispr_es_qc_wells_audit()
RETURNS TRIGGER AS $crispr_es_qc_wells_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_es_qc_wells SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_es_qc_wells SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_es_qc_wells SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_es_qc_wells_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_es_qc_wells_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_es_qc_wells
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_es_qc_wells_audit();
CREATE TABLE audit.crispr_es_qc_runs (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id character(36),
sequencing_project text,
created_at timestamp without time zone,
created_by_id integer,
species_id text
);
CREATE OR REPLACE FUNCTION public.process_crispr_es_qc_runs_audit()
RETURNS TRIGGER AS $crispr_es_qc_runs_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_es_qc_runs SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_es_qc_runs SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_es_qc_runs SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_es_qc_runs_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_es_qc_runs_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_es_qc_runs
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_es_qc_runs_audit();
