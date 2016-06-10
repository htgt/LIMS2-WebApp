ALTER TABLE audit.crispr_primers ADD COLUMN crispr_group_id integer;

CREATE TABLE audit.crispr_groups (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
gene_id text,
gene_type_id text
);
CREATE OR REPLACE FUNCTION public.process_crispr_groups_audit()
RETURNS TRIGGER AS $crispr_groups_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_groups SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_groups SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_groups SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_groups_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_groups_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_groups
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_groups_audit();

CREATE TABLE audit.crispr_group_crisprs (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
crispr_group_id integer,
crispr_id integer,
left_of_target boolean
);
CREATE OR REPLACE FUNCTION public.process_crispr_group_crisprs_audit()
RETURNS TRIGGER AS $crispr_group_crisprs_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_group_crisprs SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_group_crisprs SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_group_crisprs SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_group_crisprs_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_group_crisprs_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_group_crisprs
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_group_crisprs_audit();
