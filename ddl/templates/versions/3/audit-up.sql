CREATE TABLE audit.qc_run_seq_well_qc_seq_read (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_run_seq_well_id integer,
qc_seq_read_id text
);
GRANT SELECT ON audit.qc_run_seq_well_qc_seq_read TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_run_seq_well_qc_seq_read TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_run_seq_well_qc_seq_read_audit()
RETURNS TRIGGER AS $qc_run_seq_well_qc_seq_read_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_run_seq_well_qc_seq_read SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_run_seq_well_qc_seq_read SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_run_seq_well_qc_seq_read SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_run_seq_well_qc_seq_read_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_run_seq_well_qc_seq_read_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_run_seq_well_qc_seq_read
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_run_seq_well_qc_seq_read_audit();
CREATE TABLE audit.qc_run_seq_wells (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
qc_run_id text,
plate_name text,
well_name text
);
GRANT SELECT ON audit.qc_run_seq_wells TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_run_seq_wells TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_run_seq_wells_audit()
RETURNS TRIGGER AS $qc_run_seq_wells_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_run_seq_wells SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_run_seq_wells SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_run_seq_wells SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_run_seq_wells_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_run_seq_wells_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_run_seq_wells
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_run_seq_wells_audit();
ALTER TABLE audit.qc_test_results ADD COLUMN qc_run_seq_well_id integer;
ALTER TABLE audit.qc_test_results DROP COLUMN qc_seq_project_well_id;
ALTER TABLE audit.qc_seq_reads ADD COLUMN qc_seq_project_id text;
ALTER TABLE audit.qc_seq_reads DROP COLUMN qc_seq_project_well_id;
DROP TABLE audit.qc_seq_project_qc_seq_project_well;
DROP TABLE audit.qc_seq_project_wells;
