CREATE TABLE audit.well_barcodes (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
barcode character varying
);
CREATE OR REPLACE FUNCTION public.process_well_barcodes_audit()
RETURNS TRIGGER AS $well_barcodes_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_barcodes SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_barcodes SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_barcodes SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_barcodes_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_barcodes_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_barcodes
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_barcodes_audit();
ALTER TABLE audit.plates ADD COLUMN barcode text;
