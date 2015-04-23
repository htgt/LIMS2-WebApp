CREATE TABLE audit.process_oxygen_condition (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
oxygen_condition_id integer
);
CREATE OR REPLACE FUNCTION public.process_process_oxygen_condition_audit()
RETURNS TRIGGER AS $process_oxygen_condition_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_oxygen_condition SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_oxygen_condition SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_oxygen_condition SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_oxygen_condition_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_oxygen_condition_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_oxygen_condition
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_oxygen_condition_audit();
CREATE TABLE audit.oxygen_conditions (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text
);
CREATE OR REPLACE FUNCTION public.process_oxygen_conditions_audit()
RETURNS TRIGGER AS $oxygen_conditions_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.oxygen_conditions SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.oxygen_conditions SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.oxygen_conditions SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$oxygen_conditions_audit$ LANGUAGE plpgsql;
CREATE TRIGGER oxygen_conditions_audit
AFTER INSERT OR UPDATE OR DELETE ON public.oxygen_conditions
    FOR EACH ROW EXECUTE PROCEDURE public.process_oxygen_conditions_audit();
CREATE TABLE audit.process_doublings (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
doublings integer
);
CREATE OR REPLACE FUNCTION public.process_process_doublings_audit()
RETURNS TRIGGER AS $process_doublings_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_doublings SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_doublings SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_doublings SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_doublings_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_doublings_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_doublings
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_doublings_audit();
