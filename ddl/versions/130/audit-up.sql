ALTER TABLE audit.projects ADD COLUMN strategy_id text;
CREATE TABLE audit.strategies (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
description text
);
CREATE OR REPLACE FUNCTION public.process_strategies_audit()
RETURNS TRIGGER AS $strategies_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.strategies SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.strategies SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.strategies SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$strategies_audit$ LANGUAGE plpgsql;
CREATE TRIGGER strategies_audit
AFTER INSERT OR UPDATE OR DELETE ON public.strategies
    FOR EACH ROW EXECUTE PROCEDURE public.process_strategies_audit();
