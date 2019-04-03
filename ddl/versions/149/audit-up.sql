CREATE TABLE audit.cell_line_external (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
cell_line_id integer,
remote_identifier text,
repository text,
url text
);
CREATE OR REPLACE FUNCTION public.process_cell_line_external_audit()
RETURNS TRIGGER AS $cell_line_external_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.cell_line_external SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.cell_line_external SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.cell_line_external SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$cell_line_external_audit$ LANGUAGE plpgsql;
CREATE TRIGGER cell_line_external_audit
AFTER INSERT OR UPDATE OR DELETE ON public.cell_line_external
    FOR EACH ROW EXECUTE PROCEDURE public.process_cell_line_external_audit();
CREATE TABLE audit.cell_line_repositories (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_cell_line_repositories_audit()
RETURNS TRIGGER AS $cell_line_repositories_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.cell_line_repositories SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.cell_line_repositories SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.cell_line_repositories SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$cell_line_repositories_audit$ LANGUAGE plpgsql;
CREATE TRIGGER cell_line_repositories_audit
AFTER INSERT OR UPDATE OR DELETE ON public.cell_line_repositories
    FOR EACH ROW EXECUTE PROCEDURE public.process_cell_line_repositories_audit();
CREATE TABLE audit.cell_line_internal (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
cell_line_id integer,
origin_well_id integer,
unique_identifier character varying
);
CREATE OR REPLACE FUNCTION public.process_cell_line_internal_audit()
RETURNS TRIGGER AS $cell_line_internal_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.cell_line_internal SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.cell_line_internal SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.cell_line_internal SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$cell_line_internal_audit$ LANGUAGE plpgsql;
CREATE TRIGGER cell_line_internal_audit
AFTER INSERT OR UPDATE OR DELETE ON public.cell_line_internal
    FOR EACH ROW EXECUTE PROCEDURE public.process_cell_line_internal_audit();
ALTER TABLE audit.cell_lines ADD COLUMN description text;
