CREATE TABLE audit.process_guided_type (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
guided_type_id integer
);
CREATE OR REPLACE FUNCTION public.process_process_guided_type_audit()
RETURNS TRIGGER AS $process_guided_type_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_guided_type SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_guided_type SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_guided_type SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_guided_type_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_guided_type_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_guided_type
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_guided_type_audit();
CREATE TABLE audit.crispr_storage (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
tube_location text,
box_name text,
created_on timestamp without time zone,
crispr_id integer,
created_by_user text,
stored_by_user text
);
CREATE OR REPLACE FUNCTION public.process_crispr_storage_audit()
RETURNS TRIGGER AS $crispr_storage_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.crispr_storage SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.crispr_storage SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.crispr_storage SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$crispr_storage_audit$ LANGUAGE plpgsql;
CREATE TRIGGER crispr_storage_audit
AFTER INSERT OR UPDATE OR DELETE ON public.crispr_storage
    FOR EACH ROW EXECUTE PROCEDURE public.process_crispr_storage_audit();
CREATE TABLE audit.miseq_primer_presets (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
preset_id integer,
internal boolean,
search_width integer,
offset_width integer,
increment_value integer
);
CREATE OR REPLACE FUNCTION public.process_miseq_primer_presets_audit()
RETURNS TRIGGER AS $miseq_primer_presets_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_primer_presets SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_primer_presets SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_primer_presets SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_primer_presets_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_primer_presets_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_primer_presets
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_primer_presets_audit();
CREATE TABLE audit.trivial_offset (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
gene_id text,
crispr_offset integer
);
CREATE OR REPLACE FUNCTION public.process_trivial_offset_audit()
RETURNS TRIGGER AS $trivial_offset_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.trivial_offset SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.trivial_offset SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.trivial_offset SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$trivial_offset_audit$ LANGUAGE plpgsql;
CREATE TRIGGER trivial_offset_audit
AFTER INSERT OR UPDATE OR DELETE ON public.trivial_offset
    FOR EACH ROW EXECUTE PROCEDURE public.process_trivial_offset_audit();
CREATE TABLE audit.guided_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text
);
CREATE OR REPLACE FUNCTION public.process_guided_types_audit()
RETURNS TRIGGER AS $guided_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.guided_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.guided_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.guided_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$guided_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER guided_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.guided_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_guided_types_audit();
CREATE TABLE audit.miseq_design_presets (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
created_by integer,
genomic_threshold integer,
min_gc integer,
max_gc integer,
opt_gc integer,
min_mt integer,
max_mt integer,
opt_mt integer
);
CREATE OR REPLACE FUNCTION public.process_miseq_design_presets_audit()
RETURNS TRIGGER AS $miseq_design_presets_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_design_presets SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_design_presets SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_design_presets SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_design_presets_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_design_presets_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_design_presets
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_design_presets_audit();
CREATE TABLE audit.project_experiment (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
project_id integer,
experiment_id integer
);
CREATE OR REPLACE FUNCTION public.process_project_experiment_audit()
RETURNS TRIGGER AS $project_experiment_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.project_experiment SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.project_experiment SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.project_experiment SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$project_experiment_audit$ LANGUAGE plpgsql;
CREATE TRIGGER project_experiment_audit
AFTER INSERT OR UPDATE OR DELETE ON public.project_experiment
    FOR EACH ROW EXECUTE PROCEDURE public.process_project_experiment_audit();
