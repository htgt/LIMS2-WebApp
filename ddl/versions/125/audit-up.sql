CREATE TABLE audit.requesters (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_requesters_audit()
RETURNS TRIGGER AS $requesters_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.requesters SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.requesters SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.requesters SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$requesters_audit$ LANGUAGE plpgsql;
CREATE TRIGGER requesters_audit
AFTER INSERT OR UPDATE OR DELETE ON public.requesters
    FOR EACH ROW EXECUTE PROCEDURE public.process_requesters_audit();
ALTER TABLE audit.experiments ADD COLUMN requester text;
