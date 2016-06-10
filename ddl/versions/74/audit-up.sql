ALTER TABLE audit.projects ADD COLUMN recovery_class text;
ALTER TABLE audit.projects ADD COLUMN recovery_comment text;
ALTER TABLE audit.projects ADD COLUMN priority text;
CREATE TABLE audit.project_recovery_class (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id character varying,
description text
);
CREATE OR REPLACE FUNCTION public.process_project_recovery_class_audit()
RETURNS TRIGGER AS $project_recovery_class_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.project_recovery_class SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.project_recovery_class SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.project_recovery_class SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$project_recovery_class_audit$ LANGUAGE plpgsql;
CREATE TRIGGER project_recovery_class_audit
AFTER INSERT OR UPDATE OR DELETE ON public.project_recovery_class
    FOR EACH ROW EXECUTE PROCEDURE public.process_project_recovery_class_audit();
