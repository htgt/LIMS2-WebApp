CREATE TABLE audit.roles (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text
);
GRANT SELECT ON audit.roles TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.roles TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_roles_audit()
RETURNS TRIGGER AS $roles_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.roles SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.roles SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.roles SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$roles_audit$ LANGUAGE plpgsql;
CREATE TRIGGER roles_audit
AFTER INSERT OR UPDATE OR DELETE ON public.roles
    FOR EACH ROW EXECUTE PROCEDURE public.process_roles_audit();
CREATE TABLE audit.qc_seq_project_wells (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
qc_seq_project_id text,
plate_name text,
well_name text
);
GRANT SELECT ON audit.qc_seq_project_wells TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_seq_project_wells TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_seq_project_wells_audit()
RETURNS TRIGGER AS $qc_seq_project_wells_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_seq_project_wells SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_seq_project_wells SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_seq_project_wells SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_seq_project_wells_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_seq_project_wells_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_seq_project_wells
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_seq_project_wells_audit();
CREATE TABLE audit.schema_versions (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
version integer,
deployed_at timestamp without time zone
);
GRANT SELECT ON audit.schema_versions TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.schema_versions TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_schema_versions_audit()
RETURNS TRIGGER AS $schema_versions_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.schema_versions SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.schema_versions SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.schema_versions SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$schema_versions_audit$ LANGUAGE plpgsql;
CREATE TRIGGER schema_versions_audit
AFTER INSERT OR UPDATE OR DELETE ON public.schema_versions
    FOR EACH ROW EXECUTE PROCEDURE public.process_schema_versions_audit();
CREATE TABLE audit.qc_alignments (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
qc_seq_read_id text,
qc_eng_seq_id integer,
primer_name text,
query_start integer,
query_end integer,
query_strand integer,
target_start integer,
target_end integer,
target_strand integer,
score integer,
pass boolean,
features text,
cigar text,
op_str text
);
GRANT SELECT ON audit.qc_alignments TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_alignments TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_alignments_audit()
RETURNS TRIGGER AS $qc_alignments_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_alignments SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_alignments SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_alignments SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_alignments_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_alignments_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_alignments
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_alignments_audit();
CREATE TABLE audit.user_role (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
user_id integer,
role_id integer
);
GRANT SELECT ON audit.user_role TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.user_role TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_user_role_audit()
RETURNS TRIGGER AS $user_role_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.user_role SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.user_role SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.user_role SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$user_role_audit$ LANGUAGE plpgsql;
CREATE TRIGGER user_role_audit
AFTER INSERT OR UPDATE OR DELETE ON public.user_role
    FOR EACH ROW EXECUTE PROCEDURE public.process_user_role_audit();
CREATE TABLE audit.qc_templates (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
created_at timestamp without time zone
);
GRANT SELECT ON audit.qc_templates TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_templates TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_templates_audit()
RETURNS TRIGGER AS $qc_templates_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_templates SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_templates SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_templates SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_templates_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_templates_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_templates
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_templates_audit();
CREATE TABLE audit.qc_eng_seqs (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
method text,
params text
);
GRANT SELECT ON audit.qc_eng_seqs TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_eng_seqs TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_eng_seqs_audit()
RETURNS TRIGGER AS $qc_eng_seqs_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_eng_seqs SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_eng_seqs SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_eng_seqs SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_eng_seqs_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_eng_seqs_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_eng_seqs
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_eng_seqs_audit();
CREATE TABLE audit.qc_alignment_regions (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_alignment_id integer,
name text,
length integer,
match_count integer,
query_str text,
target_str text,
match_str text,
pass boolean
);
GRANT SELECT ON audit.qc_alignment_regions TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_alignment_regions TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_alignment_regions_audit()
RETURNS TRIGGER AS $qc_alignment_regions_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_alignment_regions SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_alignment_regions SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_alignment_regions SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_alignment_regions_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_alignment_regions_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_alignment_regions
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_alignment_regions_audit();
CREATE TABLE audit.users (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
password text
);
GRANT SELECT ON audit.users TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.users TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_users_audit()
RETURNS TRIGGER AS $users_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.users SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.users SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.users SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$users_audit$ LANGUAGE plpgsql;
CREATE TRIGGER users_audit
AFTER INSERT OR UPDATE OR DELETE ON public.users
    FOR EACH ROW EXECUTE PROCEDURE public.process_users_audit();
CREATE TABLE audit.qc_test_results (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
qc_run_id character(36),
qc_eng_seq_id integer,
qc_seq_project_well_id integer,
score integer,
pass boolean
);
GRANT SELECT ON audit.qc_test_results TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_test_results TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_test_results_audit()
RETURNS TRIGGER AS $qc_test_results_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_test_results SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_test_results SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_test_results SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_test_results_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_test_results_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_test_results
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_test_results_audit();
CREATE TABLE audit.qc_seq_reads (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
description text,
qc_seq_project_well_id integer,
primer_name text,
seq text,
length integer
);
GRANT SELECT ON audit.qc_seq_reads TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_seq_reads TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_seq_reads_audit()
RETURNS TRIGGER AS $qc_seq_reads_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_seq_reads SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_seq_reads SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_seq_reads SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_seq_reads_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_seq_reads_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_seq_reads
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_seq_reads_audit();
CREATE TABLE audit.qc_runs (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id character(36),
created_at timestamp without time zone,
created_by_id integer,
profile text,
qc_template_id integer,
software_version text,
upload_complete boolean
);
GRANT SELECT ON audit.qc_runs TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_runs TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_runs_audit()
RETURNS TRIGGER AS $qc_runs_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_runs SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_runs SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_runs SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_runs_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_runs_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_runs
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_runs_audit();
CREATE TABLE audit.qc_template_wells (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
qc_template_id integer,
name text,
qc_eng_seq_id integer
);
GRANT SELECT ON audit.qc_template_wells TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_template_wells TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_template_wells_audit()
RETURNS TRIGGER AS $qc_template_wells_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_template_wells SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_template_wells SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_template_wells SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_template_wells_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_template_wells_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_template_wells
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_template_wells_audit();
CREATE TABLE audit.qc_run_seq_project (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_run_id character(36),
qc_seq_project_id text
);
GRANT SELECT ON audit.qc_run_seq_project TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_run_seq_project TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_run_seq_project_audit()
RETURNS TRIGGER AS $qc_run_seq_project_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_run_seq_project SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_run_seq_project SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_run_seq_project SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_run_seq_project_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_run_seq_project_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_run_seq_project
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_run_seq_project_audit();
CREATE TABLE audit.qc_seq_projects (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.qc_seq_projects TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.qc_seq_projects TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_qc_seq_projects_audit()
RETURNS TRIGGER AS $qc_seq_projects_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_seq_projects SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_seq_projects SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_seq_projects SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_seq_projects_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_seq_projects_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_seq_projects
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_seq_projects_audit();
