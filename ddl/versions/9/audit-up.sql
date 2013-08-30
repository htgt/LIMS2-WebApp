ALTER TABLE audit.cassettes ADD COLUMN conditional BOOLEAN;

CREATE TABLE audit.projects (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
sponsor_id text,
allele_request text
);
GRANT SELECT ON audit.projects TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.projects TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_projects_audit()
RETURNS TRIGGER AS $projects_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.projects SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.projects SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.projects SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$projects_audit$ LANGUAGE plpgsql;
CREATE TRIGGER projects_audit
AFTER INSERT OR UPDATE OR DELETE ON public.projects
    FOR EACH ROW EXECUTE PROCEDURE public.process_projects_audit();

CREATE TABLE audit.sponsors (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
description text
);
GRANT SELECT ON audit.sponsors TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.sponsors TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_sponsors_audit()
RETURNS TRIGGER AS $sponsors_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.sponsors SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.sponsors SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.sponsors SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$sponsors_audit$ LANGUAGE plpgsql;
CREATE TRIGGER sponsors_audit
AFTER INSERT OR UPDATE OR DELETE ON public.sponsors
    FOR EACH ROW EXECUTE PROCEDURE public.process_sponsors_audit();

    
