ALTER TABLE audit.plate_types ADD COLUMN eng_seq_stage text;
ALTER TABLE audit.plate_types DROP COLUMN ens_seq_stage;
CREATE TABLE audit.crispr_damage_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
description text
);
CREATE OR REPLACE FUNCTION public.process_crispr_damage_types_audit()
RETURNS TRIGGER AS $crispr_damage_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_damage_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_damage_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_damage_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_damage_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_damage_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_damage_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_damage_types_audit();
