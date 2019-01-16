CREATE TABLE audit.process_crispr_pair (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
crispr_pair_id integer
);
CREATE OR REPLACE FUNCTION public.process_process_crispr_pair_audit()
RETURNS TRIGGER AS $process_crispr_pair_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_crispr_pair SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_crispr_pair SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_crispr_pair SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_crispr_pair_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_crispr_pair_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_crispr_pair
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_crispr_pair_audit();
CREATE TABLE audit.lab_heads (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_lab_heads_audit()
RETURNS TRIGGER AS $lab_heads_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.lab_heads SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.lab_heads SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.lab_heads SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$lab_heads_audit$ LANGUAGE plpgsql;
CREATE TRIGGER lab_heads_audit
AFTER INSERT OR UPDATE OR DELETE ON public.lab_heads
    FOR EACH ROW EXECUTE PROCEDURE public.process_lab_heads_audit();
CREATE TABLE audit.programmes (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
abbr text
);
CREATE OR REPLACE FUNCTION public.process_programmes_audit()
RETURNS TRIGGER AS $programmes_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.programmes SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.programmes SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.programmes SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$programmes_audit$ LANGUAGE plpgsql;
CREATE TRIGGER programmes_audit
AFTER INSERT OR UPDATE OR DELETE ON public.programmes
    FOR EACH ROW EXECUTE PROCEDURE public.process_programmes_audit();
CREATE TABLE audit.process_crispr_group (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
crispr_group_id integer
);
CREATE OR REPLACE FUNCTION public.process_process_crispr_group_audit()
RETURNS TRIGGER AS $process_crispr_group_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_crispr_group SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_crispr_group SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_crispr_group SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_crispr_group_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_crispr_group_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_crispr_group
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_crispr_group_audit();
ALTER TABLE audit.cell_lines ADD COLUMN description text;
ALTER TABLE audit.cell_lines ADD COLUMN origin_well integer;
CREATE TABLE audit.well_t7 (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
t7_score integer,
t7_status text,
created_by_id integer,
created_at timestamp without time zone
);
CREATE OR REPLACE FUNCTION public.process_well_t7_audit()
RETURNS TRIGGER AS $well_t7_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_t7 SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_t7 SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_t7 SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_t7_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_t7_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_t7
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_t7_audit();
