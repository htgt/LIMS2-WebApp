CREATE TABLE audit.design_append_aliases (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
design_type text,
alias text
);
CREATE OR REPLACE FUNCTION public.process_design_append_aliases_audit()
RETURNS TRIGGER AS $design_append_aliases_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_append_aliases SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_append_aliases SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_append_aliases SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_append_aliases_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_append_aliases_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_append_aliases
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_append_aliases_audit();
