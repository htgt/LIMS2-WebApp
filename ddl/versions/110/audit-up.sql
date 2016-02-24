ALTER TABLE audit.processes ADD COLUMN dna_template text;
CREATE TABLE audit.dna_templates (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_dna_templates_audit()
RETURNS TRIGGER AS $dna_templates_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.dna_templates SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.dna_templates SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.dna_templates SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$dna_templates_audit$ LANGUAGE plpgsql;
CREATE TRIGGER dna_templates_audit
AFTER INSERT OR UPDATE OR DELETE ON public.dna_templates
    FOR EACH ROW EXECUTE PROCEDURE public.process_dna_templates_audit();
