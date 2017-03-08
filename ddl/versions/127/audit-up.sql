ALTER TABLE audit.miseq_project_well_exp ADD COLUMN miseq_exp_id integer;
ALTER TABLE audit.miseq_project_well_exp DROP COLUMN experiment;
CREATE TABLE audit.miseq_experiment (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
miseq_id integer,
name text,
gene text,
mutation_reads integer,
total_reads integer
);
CREATE OR REPLACE FUNCTION public.process_miseq_experiment_audit()
RETURNS TRIGGER AS $miseq_experiment_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_experiment SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_experiment SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_experiment SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_experiment_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_experiment_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_experiment
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_experiment_audit();
