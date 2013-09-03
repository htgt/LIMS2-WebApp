CREATE TABLE audit.bac_clones (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
bac_library_id text
);
GRANT SELECT ON audit.bac_clones TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.bac_clones TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_bac_clones_audit()
RETURNS TRIGGER AS $bac_clones_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.bac_clones SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.bac_clones SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.bac_clones SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$bac_clones_audit$ LANGUAGE plpgsql;
CREATE TRIGGER bac_clones_audit
AFTER INSERT OR UPDATE OR DELETE ON public.bac_clones
    FOR EACH ROW EXECUTE PROCEDURE public.process_bac_clones_audit();
CREATE TABLE audit.design_oligo_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.design_oligo_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.design_oligo_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_design_oligo_types_audit()
RETURNS TRIGGER AS $design_oligo_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_oligo_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_oligo_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_oligo_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_oligo_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_oligo_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_oligo_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_oligo_types_audit();
CREATE TABLE audit.design_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.design_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.design_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_design_types_audit()
RETURNS TRIGGER AS $design_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_types_audit();
CREATE TABLE audit.chromosomes (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.chromosomes TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.chromosomes TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_chromosomes_audit()
RETURNS TRIGGER AS $chromosomes_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.chromosomes SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.chromosomes SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.chromosomes SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$chromosomes_audit$ LANGUAGE plpgsql;
CREATE TRIGGER chromosomes_audit
AFTER INSERT OR UPDATE OR DELETE ON public.chromosomes
    FOR EACH ROW EXECUTE PROCEDURE public.process_chromosomes_audit();
CREATE TABLE audit.bac_clone_loci (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
bac_clone_id integer,
assembly_id text,
chr_id text,
chr_start integer,
chr_end integer
);
GRANT SELECT ON audit.bac_clone_loci TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.bac_clone_loci TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_bac_clone_loci_audit()
RETURNS TRIGGER AS $bac_clone_loci_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.bac_clone_loci SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.bac_clone_loci SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.bac_clone_loci SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$bac_clone_loci_audit$ LANGUAGE plpgsql;
CREATE TRIGGER bac_clone_loci_audit
AFTER INSERT OR UPDATE OR DELETE ON public.bac_clone_loci
    FOR EACH ROW EXECUTE PROCEDURE public.process_bac_clone_loci_audit();
CREATE TABLE audit.gene_design (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
gene_id text,
design_id integer,
created_by integer,
created_at timestamp without time zone
);
GRANT SELECT ON audit.gene_design TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.gene_design TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_gene_design_audit()
RETURNS TRIGGER AS $gene_design_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.gene_design SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.gene_design SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.gene_design SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$gene_design_audit$ LANGUAGE plpgsql;
CREATE TRIGGER gene_design_audit
AFTER INSERT OR UPDATE OR DELETE ON public.gene_design
    FOR EACH ROW EXECUTE PROCEDURE public.process_gene_design_audit();
CREATE TABLE audit.design_oligos (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
design_id integer,
design_oligo_type_id text,
seq text
);
GRANT SELECT ON audit.design_oligos TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.design_oligos TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_design_oligos_audit()
RETURNS TRIGGER AS $design_oligos_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_oligos SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_oligos SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_oligos SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_oligos_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_oligos_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_oligos
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_oligos_audit();
CREATE TABLE audit.bac_libraries (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.bac_libraries TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.bac_libraries TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_bac_libraries_audit()
RETURNS TRIGGER AS $bac_libraries_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.bac_libraries SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.bac_libraries SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.bac_libraries SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$bac_libraries_audit$ LANGUAGE plpgsql;
CREATE TRIGGER bac_libraries_audit
AFTER INSERT OR UPDATE OR DELETE ON public.bac_libraries
    FOR EACH ROW EXECUTE PROCEDURE public.process_bac_libraries_audit();
CREATE TABLE audit.design_oligo_loci (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
design_oligo_id integer,
assembly_id text,
chr_id text,
chr_start integer,
chr_end integer,
chr_strand integer
);
GRANT SELECT ON audit.design_oligo_loci TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.design_oligo_loci TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_design_oligo_loci_audit()
RETURNS TRIGGER AS $design_oligo_loci_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_oligo_loci SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_oligo_loci SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_oligo_loci SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_oligo_loci_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_oligo_loci_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_oligo_loci
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_oligo_loci_audit();
CREATE TABLE audit.designs (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
created_by integer,
created_at timestamp without time zone,
design_type_id text,
phase integer,
validated_by_annotation text,
target_transcript text
);
GRANT SELECT ON audit.designs TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.designs TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_designs_audit()
RETURNS TRIGGER AS $designs_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.designs SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.designs SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.designs SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$designs_audit$ LANGUAGE plpgsql;
CREATE TRIGGER designs_audit
AFTER INSERT OR UPDATE OR DELETE ON public.designs
    FOR EACH ROW EXECUTE PROCEDURE public.process_designs_audit();
CREATE TABLE audit.genotyping_primer_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.genotyping_primer_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.genotyping_primer_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_genotyping_primer_types_audit()
RETURNS TRIGGER AS $genotyping_primer_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.genotyping_primer_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.genotyping_primer_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.genotyping_primer_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$genotyping_primer_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER genotyping_primer_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.genotyping_primer_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_genotyping_primer_types_audit();
CREATE TABLE audit.design_comment_categories (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text
);
GRANT SELECT ON audit.design_comment_categories TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.design_comment_categories TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_design_comment_categories_audit()
RETURNS TRIGGER AS $design_comment_categories_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_comment_categories SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_comment_categories SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_comment_categories SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_comment_categories_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_comment_categories_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_comment_categories
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_comment_categories_audit();
CREATE TABLE audit.design_comments (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
design_comment_category_id integer,
design_id integer,
comment_text text,
is_public boolean,
created_by integer,
created_at timestamp without time zone
);
GRANT SELECT ON audit.design_comments TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.design_comments TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_design_comments_audit()
RETURNS TRIGGER AS $design_comments_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.design_comments SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.design_comments SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.design_comments SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$design_comments_audit$ LANGUAGE plpgsql;
CREATE TRIGGER design_comments_audit
AFTER INSERT OR UPDATE OR DELETE ON public.design_comments
    FOR EACH ROW EXECUTE PROCEDURE public.process_design_comments_audit();
CREATE TABLE audit.assemblies (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.assemblies TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.assemblies TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_assemblies_audit()
RETURNS TRIGGER AS $assemblies_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.assemblies SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.assemblies SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.assemblies SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$assemblies_audit$ LANGUAGE plpgsql;
CREATE TRIGGER assemblies_audit
AFTER INSERT OR UPDATE OR DELETE ON public.assemblies
    FOR EACH ROW EXECUTE PROCEDURE public.process_assemblies_audit();
CREATE TABLE audit.genotyping_primers (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
genotyping_primer_type_id text,
design_id integer,
seq text
);
GRANT SELECT ON audit.genotyping_primers TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.genotyping_primers TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_genotyping_primers_audit()
RETURNS TRIGGER AS $genotyping_primers_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.genotyping_primers SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.genotyping_primers SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.genotyping_primers SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$genotyping_primers_audit$ LANGUAGE plpgsql;
CREATE TRIGGER genotyping_primers_audit
AFTER INSERT OR UPDATE OR DELETE ON public.genotyping_primers
    FOR EACH ROW EXECUTE PROCEDURE public.process_genotyping_primers_audit();
