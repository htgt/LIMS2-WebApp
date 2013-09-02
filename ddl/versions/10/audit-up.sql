CREATE TABLE audit.cell_lines (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text
);
GRANT SELECT ON audit.cell_lines TO [% ro_role %];
GRANT SELECT,INSERT ON audit.cell_lines TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_cell_lines_audit()
RETURNS TRIGGER AS $cell_lines_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.cell_lines SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.cell_lines SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.cell_lines SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$cell_lines_audit$ LANGUAGE plpgsql;
CREATE TRIGGER cell_lines_audit
AFTER INSERT OR UPDATE OR DELETE ON public.cell_lines
    FOR EACH ROW EXECUTE PROCEDURE public.process_cell_lines_audit();
