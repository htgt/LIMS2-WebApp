CREATE TABLE audit.well_lab_number (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
lab_number text
);
GRANT SELECT ON audit.well_lab_number TO [% ro_role %];
GRANT SELECT,INSERT ON audit.well_lab_number TO [% rw_role %];

CREATE OR REPLACE FUNCTION public.process_well_lab_number_audit()
RETURNS TRIGGER AS $well_lab_number_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_lab_number SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_lab_number SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_lab_number SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_lab_number_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_lab_number_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_lab_number
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_lab_number_audit();
