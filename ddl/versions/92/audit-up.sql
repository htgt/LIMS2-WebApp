CREATE TABLE audit.process_parameters (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
parameter_name text,
parameter_value text
);
CREATE OR REPLACE FUNCTION public.process_process_parameters_audit()
RETURNS TRIGGER AS $process_parameters_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_parameters SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_parameters SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_parameters SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_parameters_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_parameters_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_parameters
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_parameters_audit();
