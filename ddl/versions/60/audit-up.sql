ALTER TABLE audit.designs ADD COLUMN global_arm_shortened integer;

CREATE TABLE audit.process_global_arm_shortening_design (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
design_id integer
);
CREATE OR REPLACE FUNCTION public.process_process_global_arm_shortening_design_audit()
RETURNS TRIGGER AS $process_global_arm_shortening_design_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_global_arm_shortening_design SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_global_arm_shortening_design SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_global_arm_shortening_design SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_global_arm_shortening_design_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_global_arm_shortening_design_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_global_arm_shortening_design
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_global_arm_shortening_design_audit();
