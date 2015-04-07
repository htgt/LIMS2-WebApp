-- crispr_tracker_rnas table
CREATE TABLE audit.crispr_tracker_rnas (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text
);
CREATE OR REPLACE FUNCTION public.process_crispr_tracker_rnas_audit()
RETURNS TRIGGER AS $crispr_tracker_rnas_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_tracker_rnas SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_tracker_rnas SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_tracker_rnas SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_tracker_rnas_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_tracker_rnas_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_tracker_rnas
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_tracker_rnas_audit();

-- process_crispr_tracker_rna table
CREATE TABLE audit.process_crispr_tracker_rna (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
crispr_tracker_rna_id integer
);
CREATE OR REPLACE FUNCTION public.process_process_crispr_tracker_rna_audit()
RETURNS TRIGGER AS $process_crispr_tracker_rna_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_crispr_tracker_rna SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_crispr_tracker_rna SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_crispr_tracker_rna SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_crispr_tracker_rna_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_crispr_tracker_rna_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_crispr_tracker_rna
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_crispr_tracker_rna_audit();
