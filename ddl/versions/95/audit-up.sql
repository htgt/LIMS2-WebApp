CREATE TABLE audit.well_assembly_qc (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
assembly_well_id integer,
qc_type assembly_well_qc_type,
value assembly_well_qc_type
);
CREATE OR REPLACE FUNCTION public.process_well_assembly_qc_audit()
RETURNS TRIGGER AS $well_assembly_qc_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_assembly_qc SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_assembly_qc SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_assembly_qc SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_assembly_qc_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_assembly_qc_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_assembly_qc
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_assembly_qc_audit();
CREATE TABLE audit.crispr_plate_appends (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
plate_id integer,
append_id character varying
);
CREATE OR REPLACE FUNCTION public.process_crispr_plate_appends_audit()
RETURNS TRIGGER AS $crispr_plate_appends_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_plate_appends SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_plate_appends SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_plate_appends SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_plate_appends_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_plate_appends_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_plate_appends
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_plate_appends_audit();
CREATE TABLE audit.crispr_plate_appends_type (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id character varying
);
CREATE OR REPLACE FUNCTION public.process_crispr_plate_appends_type_audit()
RETURNS TRIGGER AS $crispr_plate_appends_type_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_plate_appends_type SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_plate_appends_type SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_plate_appends_type SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_plate_appends_type_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_plate_appends_type_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_plate_appends_type
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_plate_appends_type_audit();
