CREATE TABLE audit.sequencing_project_backups (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
seq_project_id integer,
directory text,
creation_date timestamp without time zone
);
CREATE OR REPLACE FUNCTION public.process_sequencing_project_backups_audit()
RETURNS TRIGGER AS $sequencing_project_backups_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.sequencing_project_backups SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.sequencing_project_backups SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.sequencing_project_backups SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$sequencing_project_backups_audit$ LANGUAGE plpgsql;
CREATE TRIGGER sequencing_project_backups_audit
AFTER INSERT OR UPDATE OR DELETE ON public.sequencing_project_backups
    FOR EACH ROW EXECUTE PROCEDURE public.process_sequencing_project_backups_audit();
