CREATE TABLE audit.crispr_primers_loci (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
crispr_oligo_id integer,
assembly_id text,
chr_id integer,
chr_start integer,
chr_end integer,
chr_strand integer
);
CREATE OR REPLACE FUNCTION public.process_crispr_primers_loci_audit()
RETURNS TRIGGER AS $crispr_primers_loci_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_primers_loci SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_primers_loci SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_primers_loci SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_primers_loci_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_primers_loci_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_primers_loci
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_primers_loci_audit();
CREATE TABLE audit.crispr_primers (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
crispr_oligo_id integer,
crispr_pair_id integer,
crispr_id integer,
primer_name text,
primer_seq text,
tm numeric,
gc_content numeric
);
CREATE OR REPLACE FUNCTION public.process_crispr_primers_audit()
RETURNS TRIGGER AS $crispr_primers_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_primers SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_primers SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_primers SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_primers_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_primers_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_primers
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_primers_audit();
ALTER TABLE audit.genotyping_primers ADD COLUMN tm numeric;
ALTER TABLE audit.genotyping_primers ADD COLUMN gc_content numeric;
CREATE TABLE audit.genotyping_primers_loci (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
genotyping_primer_id integer,
assembly_id text,
chr_id integer,
chr_start integer,
chr_end integer,
chr_strand integer
);
CREATE OR REPLACE FUNCTION public.process_genotyping_primers_loci_audit()
RETURNS TRIGGER AS $genotyping_primers_loci_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.genotyping_primers_loci SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.genotyping_primers_loci SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.genotyping_primers_loci SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$genotyping_primers_loci_audit$ LANGUAGE plpgsql;
CREATE TRIGGER genotyping_primers_loci_audit
AFTER INSERT OR UPDATE OR DELETE ON public.genotyping_primers_loci
    FOR EACH ROW EXECUTE PROCEDURE public.process_genotyping_primers_loci_audit();
CREATE TABLE audit.crispr_primer_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
primer_name text
);
CREATE OR REPLACE FUNCTION public.process_crispr_primer_types_audit()
RETURNS TRIGGER AS $crispr_primer_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_primer_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_primer_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_primer_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_primer_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_primer_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_primer_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_primer_types_audit();
