CREATE TABLE audit.experiments (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
project_id integer,
design_id integer,
crispr_id integer,
crispr_pair_id integer,
crispr_group_id integer
);
CREATE OR REPLACE FUNCTION public.process_experiments_audit()
RETURNS TRIGGER AS $experiments_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.experiments SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.experiments SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.experiments SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$experiments_audit$ LANGUAGE plpgsql;
CREATE TRIGGER experiments_audit
AFTER INSERT OR UPDATE OR DELETE ON public.experiments
    FOR EACH ROW EXECUTE PROCEDURE public.process_experiments_audit();
