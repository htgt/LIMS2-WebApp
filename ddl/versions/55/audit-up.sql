CREATE TABLE audit.process_nuclease (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
nuclease_id integer
);
CREATE OR REPLACE FUNCTION public.process_process_nuclease_audit()
RETURNS TRIGGER AS $process_nuclease_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_nuclease SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_nuclease SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_nuclease SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_nuclease_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_nuclease_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_nuclease
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_nuclease_audit();
CREATE TABLE audit.nucleases (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text
);
CREATE OR REPLACE FUNCTION public.process_nucleases_audit()
RETURNS TRIGGER AS $nucleases_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.nucleases SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.nucleases SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.nucleases SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$nucleases_audit$ LANGUAGE plpgsql;
CREATE TRIGGER nucleases_audit
AFTER INSERT OR UPDATE OR DELETE ON public.nucleases
    FOR EACH ROW EXECUTE PROCEDURE public.process_nucleases_audit();
