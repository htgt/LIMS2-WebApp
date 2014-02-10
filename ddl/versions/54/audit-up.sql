CREATE TABLE audit.well_targeting_neo_pass (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
result text,
created_at timestamp without time zone,
created_by_id integer
);
CREATE OR REPLACE FUNCTION public.process_well_targeting_neo_pass_audit()
RETURNS TRIGGER AS $well_targeting_neo_pass_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_targeting_neo_pass SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_targeting_neo_pass SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_targeting_neo_pass SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_targeting_neo_pass_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_targeting_neo_pass_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_targeting_neo_pass
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_targeting_neo_pass_audit();
CREATE TABLE audit.design_attempts (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
design_parameters text,
gene_id text,
status text,
fail text,
error text,
design_ids text,
species_id text,
created_by integer,
created_at timestamp without time zone,
comment text
);
CREATE OR REPLACE FUNCTION public.process_design_attempts_audit()
RETURNS TRIGGER AS $design_attempts_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_attempts SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_attempts SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_attempts SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_attempts_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_attempts_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_attempts
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_attempts_audit();
