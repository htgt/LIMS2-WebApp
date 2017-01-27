CREATE TABLE audit.miseq_classification (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_miseq_classification_audit()
RETURNS TRIGGER AS $miseq_classification_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_classification SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_classification SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_classification SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_classification_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_classification_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_classification
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_classification_audit();
CREATE TABLE audit.miseq_project_well_exp (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
miseq_well_id integer,
experiment text,
classification text
);
CREATE OR REPLACE FUNCTION public.process_miseq_project_well_exp_audit()
RETURNS TRIGGER AS $miseq_project_well_exp_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_project_well_exp SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_project_well_exp SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_project_well_exp SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_project_well_exp_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_project_well_exp_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_project_well_exp
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_project_well_exp_audit();
CREATE TABLE audit.miseq_projects (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
creation_date timestamp without time zone
);
CREATE OR REPLACE FUNCTION public.process_miseq_projects_audit()
RETURNS TRIGGER AS $miseq_projects_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_projects SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_projects SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_projects SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_projects_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_projects_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_projects
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_projects_audit();
CREATE TABLE audit.miseq_project_well (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
miseq_plate_id integer,
illumina_index integer,
status text
);
CREATE OR REPLACE FUNCTION public.process_miseq_project_well_audit()
RETURNS TRIGGER AS $miseq_project_well_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_project_well SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_project_well SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_project_well SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_project_well_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_project_well_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_project_well
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_project_well_audit();
CREATE TABLE audit.miseq_status (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_miseq_status_audit()
RETURNS TRIGGER AS $miseq_status_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_status SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_status SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_status SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_status_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_status_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_status
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_status_audit();
