CREATE TABLE audit.priorities (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_priorities_audit()
RETURNS TRIGGER AS $priorities_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.priorities SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.priorities SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.priorities SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$priorities_audit$ LANGUAGE plpgsql;
CREATE TRIGGER priorities_audit
AFTER INSERT OR UPDATE OR DELETE ON public.priorities
    FOR EACH ROW EXECUTE PROCEDURE public.process_priorities_audit();
CREATE TABLE audit.messages (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
message text,
created_date timestamp with time zone,
expiry_date timestamp with time zone,
priority text,
wge boolean,
lims boolean,
htgt boolean
);
CREATE OR REPLACE FUNCTION public.process_messages_audit()
RETURNS TRIGGER AS $messages_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.messages SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.messages SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.messages SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$messages_audit$ LANGUAGE plpgsql;
CREATE TRIGGER messages_audit
AFTER INSERT OR UPDATE OR DELETE ON public.messages
    FOR EACH ROW EXECUTE PROCEDURE public.process_messages_audit();
