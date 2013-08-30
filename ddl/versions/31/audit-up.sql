CREATE TABLE audit.crisprs (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
seq text,
species_id text,
crispr_loci_type_id text,
off_target_outlier boolean,
comment text
);
GRANT SELECT ON audit.crisprs TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.crisprs TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_crisprs_audit()
RETURNS TRIGGER AS $crisprs_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crisprs SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crisprs SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crisprs SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crisprs_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crisprs_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crisprs
    FOR EACH ROW EXECUTE PROCEDURE public.process_crisprs_audit();

CREATE TABLE audit.crispr_loci (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
crispr_id integer,
assembly_id text,
chr_id integer,
chr_start integer,
chr_end integer,
chr_strand integer
);
GRANT SELECT ON audit.crispr_loci TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.crispr_loci TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_crispr_loci_audit()
RETURNS TRIGGER AS $crispr_loci_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_loci SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_loci SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_loci SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_loci_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_loci_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_loci
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_loci_audit();

CREATE TABLE audit.crispr_loci_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.crispr_loci_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.crispr_loci_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_crispr_loci_types_audit()
RETURNS TRIGGER AS $crispr_loci_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_loci_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_loci_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_loci_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_loci_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_loci_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_loci_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_loci_types_audit();

CREATE TABLE audit.process_crispr (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
crispr_id integer
);
GRANT SELECT ON audit.process_crispr TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_crispr TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_crispr_audit()
RETURNS TRIGGER AS $process_crispr_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_crispr SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_crispr SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_crispr SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_crispr_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_crispr_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_crispr
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_crispr_audit();
