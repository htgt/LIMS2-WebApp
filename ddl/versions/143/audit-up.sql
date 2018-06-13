CREATE TABLE audit.miseq_hdr_template (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
design_id integer,
template text
);
CREATE OR REPLACE FUNCTION public.process_miseq_hdr_template_audit()
RETURNS TRIGGER AS $miseq_hdr_template_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_hdr_template SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_hdr_template SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_hdr_template SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_hdr_template_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_hdr_template_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_hdr_template
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_hdr_template_audit();
