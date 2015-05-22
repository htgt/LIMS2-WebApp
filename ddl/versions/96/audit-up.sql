CREATE TABLE audit.crispr_validation (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
crispr_id integer,
crispr_es_qc_well_id integer,
validated boolean
);
CREATE OR REPLACE FUNCTION public.process_crispr_validation_audit()
RETURNS TRIGGER AS $crispr_validation_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_validation SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_validation SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_validation SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_validation_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_validation_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_validation
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_validation_audit();
