CREATE TABLE audit.pipelines (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_pipelines_audit()
RETURNS TRIGGER AS $pipelines_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.pipelines SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.pipelines SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.pipelines SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$pipelines_audit$ LANGUAGE plpgsql;
CREATE TRIGGER pipelines_audit
AFTER INSERT OR UPDATE OR DELETE ON public.pipelines
    FOR EACH ROW EXECUTE PROCEDURE public.process_pipelines_audit();
ALTER TABLE audit.user_preferences ADD COLUMN default_pipeline_id text;
