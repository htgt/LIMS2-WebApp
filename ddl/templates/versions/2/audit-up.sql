ALTER TABLE audit.qc_seq_project_wells DROP COLUMN qc_seq_project_id;

CREATE TABLE audit.qc_seq_project_qc_seq_project_well (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_seq_project_id text,
qc_seq_project_well_id integer
);
GRANT SELECT ON audit.qc_seq_project_qc_seq_project_well TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_seq_project_qc_seq_project_well TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_seq_project_qc_seq_project_well_audit()
RETURNS TRIGGER AS $qc_seq_project_qc_seq_project_well_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_seq_project_qc_seq_project_well SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_seq_project_qc_seq_project_well SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_seq_project_qc_seq_project_well SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_seq_project_qc_seq_project_well_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_seq_project_qc_seq_project_well_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_seq_project_qc_seq_project_well
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_seq_project_qc_seq_project_well_audit();
