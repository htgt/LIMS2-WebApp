CREATE TABLE audit.design_oligo_appends (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
design_oligo_type_id text,
seq text
);
CREATE OR REPLACE FUNCTION public.process_design_oligo_appends_audit()
RETURNS TRIGGER AS $design_oligo_appends_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_oligo_appends SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_oligo_appends SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_oligo_appends SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_oligo_appends_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_oligo_appends_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_oligo_appends
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_oligo_appends_audit();
