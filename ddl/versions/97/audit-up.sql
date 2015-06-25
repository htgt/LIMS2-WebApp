CREATE TABLE audit.well_het_status (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
five_prime boolean,
three_prime boolean
);
CREATE OR REPLACE FUNCTION public.process_well_het_status_audit()
RETURNS TRIGGER AS $well_het_status_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_het_status SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_het_status SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_het_status SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_het_status_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_het_status_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_het_status
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_het_status_audit();
