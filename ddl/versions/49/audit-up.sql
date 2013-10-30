DROP TRIGGER crispr_pairs_audit ON crispr_pairs;
DROP TABLE audit.crispr_pairs;
CREATE TABLE audit.crispr_pairs (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
left_crispr_id integer,
right_crispr_id integer,
spacer integer,
off_target_summary text
);
CREATE OR REPLACE FUNCTION public.process_crispr_pairs_audit()
RETURNS TRIGGER AS $crispr_pairs_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_pairs SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_pairs SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_pairs SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_pairs_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_pairs_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_pairs
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_pairs_audit();
