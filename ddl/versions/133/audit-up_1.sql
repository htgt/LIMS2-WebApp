ALTER TABLE audit.miseq_experiment ADD COLUMN old_miseq_id integer;
CREATE TABLE audit.miseq_plate (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
plate_id integer,
run_id integer,
is_384 boolean,
results_available boolean
);
CREATE OR REPLACE FUNCTION public.process_miseq_plate_audit()
RETURNS TRIGGER AS $miseq_plate_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_plate SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_plate SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_plate SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_plate_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_plate_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_plate
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_plate_audit();
CREATE TABLE audit.miseq_well_experiment (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
well_id integer,
miseq_exp_id integer,
classification text,
frameshifted boolean,
status text
);
CREATE OR REPLACE FUNCTION public.process_miseq_well_experiment_audit()
RETURNS TRIGGER AS $miseq_well_experiment_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_well_experiment SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_well_experiment SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_well_experiment SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_well_experiment_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_well_experiment_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_well_experiment
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_well_experiment_audit();
