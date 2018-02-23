ALTER TABLE audit.users ADD COLUMN first_login boolean;
CREATE TABLE audit.crispr_storage (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
tube_location text,
box_name text,
created_on timestamp without time zone,
crispr_id integer,
created_by_user text,
stored_by_user text
);
CREATE OR REPLACE FUNCTION public.process_crispr_storage_audit()
RETURNS TRIGGER AS $crispr_storage_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_storage SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_storage SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_storage SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_storage_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_storage_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_storage
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_storage_audit();
CREATE TABLE audit.project_experiment (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
project_id integer,
experiment_id integer
);
CREATE OR REPLACE FUNCTION public.process_project_experiment_audit()
RETURNS TRIGGER AS $project_experiment_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.project_experiment SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.project_experiment SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.project_experiment SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$project_experiment_audit$ LANGUAGE plpgsql;
CREATE TRIGGER project_experiment_audit
AFTER INSERT OR UPDATE OR DELETE ON public.project_experiment
    FOR EACH ROW EXECUTE PROCEDURE public.process_project_experiment_audit();
