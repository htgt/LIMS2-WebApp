CREATE TABLE audit.amplicons (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
amplicon_type text,
seq text
);
CREATE OR REPLACE FUNCTION public.process_amplicons_audit()
RETURNS TRIGGER AS $amplicons_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.amplicons SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.amplicons SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.amplicons SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$amplicons_audit$ LANGUAGE plpgsql;
CREATE TRIGGER amplicons_audit
AFTER INSERT OR UPDATE OR DELETE ON public.amplicons
    FOR EACH ROW EXECUTE PROCEDURE public.process_amplicons_audit();
CREATE TABLE audit.amplicon_loci (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
amplicon_id integer,
chr_start integer,
chr_end integer,
chr_strand integer,
chr_id integer,
assembly_id text
);
CREATE OR REPLACE FUNCTION public.process_amplicon_loci_audit()
RETURNS TRIGGER AS $amplicon_loci_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.amplicon_loci SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.amplicon_loci SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.amplicon_loci SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$amplicon_loci_audit$ LANGUAGE plpgsql;
CREATE TRIGGER amplicon_loci_audit
AFTER INSERT OR UPDATE OR DELETE ON public.amplicon_loci
    FOR EACH ROW EXECUTE PROCEDURE public.process_amplicon_loci_audit();
CREATE TABLE audit.design_amplicons (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
design_id integer,
amplicon_id integer
);
CREATE OR REPLACE FUNCTION public.process_design_amplicons_audit()
RETURNS TRIGGER AS $design_amplicons_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_amplicons SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_amplicons SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_amplicons SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_amplicons_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_amplicons_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_amplicons
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_amplicons_audit();
CREATE TABLE audit.amplicon_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_amplicon_types_audit()
RETURNS TRIGGER AS $amplicon_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.amplicon_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.amplicon_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.amplicon_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$amplicon_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER amplicon_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.amplicon_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_amplicon_types_audit();
