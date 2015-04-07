ALTER TABLE audit.projects DROP COLUMN sponsor_id;
ALTER TABLE audit.projects DROP COLUMN allele_request;

CREATE TABLE audit.old_projects (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
sponsor_id text,
allele_request text,
gene_id text,
targeting_type text,
species_id text,
htgt_project_id integer,
effort_concluded boolean,
recovery_comment text,
priority text,
recovery_class_id integer
);
CREATE OR REPLACE FUNCTION public.process_old_projects_audit()
RETURNS TRIGGER AS $old_projects_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.old_projects SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.old_projects SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.old_projects SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$old_projects_audit$ LANGUAGE plpgsql;
CREATE TRIGGER old_projects_audit
AFTER INSERT OR UPDATE OR DELETE ON public.old_projects
    FOR EACH ROW EXECUTE PROCEDURE public.process_old_projects_audit();
CREATE TABLE audit.project_sponsors (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
project_id integer,
sponsor_id text
);
CREATE OR REPLACE FUNCTION public.process_project_sponsors_audit()
RETURNS TRIGGER AS $project_sponsors_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.project_sponsors SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.project_sponsors SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.project_sponsors SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$project_sponsors_audit$ LANGUAGE plpgsql;
CREATE TRIGGER project_sponsors_audit
AFTER INSERT OR UPDATE OR DELETE ON public.project_sponsors
    FOR EACH ROW EXECUTE PROCEDURE public.process_project_sponsors_audit();
CREATE TABLE audit.old_project_alleles (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
project_id integer,
allele_type text,
cassette_function text,
mutation_type text
);
CREATE OR REPLACE FUNCTION public.process_old_project_alleles_audit()
RETURNS TRIGGER AS $old_project_alleles_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.old_project_alleles SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.old_project_alleles SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.old_project_alleles SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$old_project_alleles_audit$ LANGUAGE plpgsql;
CREATE TRIGGER old_project_alleles_audit
AFTER INSERT OR UPDATE OR DELETE ON public.old_project_alleles
    FOR EACH ROW EXECUTE PROCEDURE public.process_old_project_alleles_audit();
