CREATE TABLE audit.sequencing_projects (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
created_by_id integer,
created_at timestamp without time zone,
sub_projects integer,
qc boolean,
available_results boolean,
abandoned boolean,
is_384 boolean
);
CREATE OR REPLACE FUNCTION public.process_sequencing_projects_audit()
RETURNS TRIGGER AS $sequencing_projects_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.sequencing_projects SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.sequencing_projects SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.sequencing_projects SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$sequencing_projects_audit$ LANGUAGE plpgsql;
CREATE TRIGGER sequencing_projects_audit
AFTER INSERT OR UPDATE OR DELETE ON public.sequencing_projects
    FOR EACH ROW EXECUTE PROCEDURE public.process_sequencing_projects_audit();
CREATE TABLE audit.sequencing_project_primers (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
seq_project_id integer,
primer_id text
);
CREATE OR REPLACE FUNCTION public.process_sequencing_project_primers_audit()
RETURNS TRIGGER AS $sequencing_project_primers_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.sequencing_project_primers SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.sequencing_project_primers SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.sequencing_project_primers SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$sequencing_project_primers_audit$ LANGUAGE plpgsql;
CREATE TRIGGER sequencing_project_primers_audit
AFTER INSERT OR UPDATE OR DELETE ON public.sequencing_project_primers
    FOR EACH ROW EXECUTE PROCEDURE public.process_sequencing_project_primers_audit();
CREATE TABLE audit.sequencing_project_templates (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
seq_project_id integer,
qc_template_id integer
);
CREATE OR REPLACE FUNCTION public.process_sequencing_project_templates_audit()
RETURNS TRIGGER AS $sequencing_project_templates_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.sequencing_project_templates SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.sequencing_project_templates SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.sequencing_project_templates SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$sequencing_project_templates_audit$ LANGUAGE plpgsql;
CREATE TRIGGER sequencing_project_templates_audit
AFTER INSERT OR UPDATE OR DELETE ON public.sequencing_project_templates
    FOR EACH ROW EXECUTE PROCEDURE public.process_sequencing_project_templates_audit();
CREATE TABLE audit.sequencing_primer_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_sequencing_primer_types_audit()
RETURNS TRIGGER AS $sequencing_primer_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.sequencing_primer_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.sequencing_primer_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.sequencing_primer_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$sequencing_primer_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER sequencing_primer_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.sequencing_primer_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_sequencing_primer_types_audit();
