CREATE TABLE audit.cached_reports (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id character(36),
report_class text,
params text,
expires timestamp without time zone
);
GRANT SELECT ON audit.cached_reports TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.cached_reports TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_cached_reports_audit()
RETURNS TRIGGER AS $cached_reports_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.cached_reports SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.cached_reports SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.cached_reports SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$cached_reports_audit$ LANGUAGE plpgsql;
CREATE TRIGGER cached_reports_audit
AFTER INSERT OR UPDATE OR DELETE ON public.cached_reports
    FOR EACH ROW EXECUTE PROCEDURE public.process_cached_reports_audit();
