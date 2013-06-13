CREATE TABLE audit.design_targets (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
gene_name text,
ensembl_gene_id, text,
ensembl_exon_id text,
exon_size integer,
exon_rank integer,
canonical_transcript text,
species_id text,
assembly_id text,
build_id integer,
chr_id integer,
chr_start integer,
chr_end integer,
chr_strand integer,
automatically_picked boolean,
comment text
);
GRANT SELECT ON audit.design_targets TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.design_targets TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_design_targets_audit()
RETURNS TRIGGER AS $design_targets_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_targets SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_targets SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_targets SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_targets_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_targets_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_targets
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_targets_audit();
