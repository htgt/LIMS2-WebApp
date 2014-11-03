ALTER TABLE audit.well_barcodes ADD COLUMN barcode_state text;
ALTER TABLE audit.well_barcodes ADD COLUMN root_piq_well_id INT;

ALTER TABLE audit.plates ADD COLUMN version INT;

CREATE TABLE audit.barcode_states (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
description text
);
CREATE OR REPLACE FUNCTION public.process_barcode_states_audit()
RETURNS TRIGGER AS $barcode_states_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.barcode_states SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.barcode_states SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.barcode_states SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$barcode_states_audit$ LANGUAGE plpgsql;
CREATE TRIGGER barcode_states_audit
AFTER INSERT OR UPDATE OR DELETE ON public.barcode_states
    FOR EACH ROW EXECUTE PROCEDURE public.process_barcode_states_audit();
CREATE TABLE audit.barcode_events(
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
barcode text,
old_state text,
new_state text,
old_well_id integer,
new_well_id integer,
comment text,
created_by integer,
created_at timestamp without time zone
);
CREATE OR REPLACE FUNCTION public.process_barcode_events_audit()
RETURNS TRIGGER AS $barcode_events_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.barcode_events SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.barcode_events SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.barcode_events SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$barcode_events_audit$ LANGUAGE plpgsql;
CREATE TRIGGER barcode_events_audit
AFTER INSERT OR UPDATE OR DELETE ON public.barcode_events
    FOR EACH ROW EXECUTE PROCEDURE public.process_barcode_events_audit();
