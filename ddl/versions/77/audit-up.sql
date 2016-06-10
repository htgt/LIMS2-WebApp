CREATE TABLE audit.fp_picking_list (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
active boolean,
created_by integer,
created_at timestamp without time zone
);
CREATE OR REPLACE FUNCTION public.process_fp_picking_list_audit()
RETURNS TRIGGER AS $fp_picking_list_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.fp_picking_list SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.fp_picking_list SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.fp_picking_list SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$fp_picking_list_audit$ LANGUAGE plpgsql;
CREATE TRIGGER fp_picking_list_audit
AFTER INSERT OR UPDATE OR DELETE ON public.fp_picking_list
    FOR EACH ROW EXECUTE PROCEDURE public.process_fp_picking_list_audit();
CREATE TABLE audit.fp_picking_list_well_barcode (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
fp_picking_list_id integer,
well_barcode text,
picked boolean
);
CREATE OR REPLACE FUNCTION public.process_fp_picking_list_well_barcode_audit()
RETURNS TRIGGER AS $fp_picking_list_well_barcode_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.fp_picking_list_well_barcode SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.fp_picking_list_well_barcode SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.fp_picking_list_well_barcode SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$fp_picking_list_well_barcode_audit$ LANGUAGE plpgsql;
CREATE TRIGGER fp_picking_list_well_barcode_audit
AFTER INSERT OR UPDATE OR DELETE ON public.fp_picking_list_well_barcode
    FOR EACH ROW EXECUTE PROCEDURE public.process_fp_picking_list_well_barcode_audit();
