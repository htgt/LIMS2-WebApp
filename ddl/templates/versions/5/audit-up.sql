CREATE TABLE audit.plate_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.plate_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.plate_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_plate_types_audit()
RETURNS TRIGGER AS $plate_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.plate_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.plate_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.plate_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$plate_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER plate_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.plate_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_plate_types_audit();
CREATE TABLE audit.process_backbone (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
backbone text
);
GRANT SELECT ON audit.process_backbone TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_backbone TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_backbone_audit()
RETURNS TRIGGER AS $process_backbone_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_backbone SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_backbone SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_backbone SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_backbone_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_backbone_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_backbone
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_backbone_audit();
CREATE TABLE audit.process_output_well (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
well_id integer
);
GRANT SELECT ON audit.process_output_well TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_output_well TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_output_well_audit()
RETURNS TRIGGER AS $process_output_well_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_output_well SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_output_well SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_output_well SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_output_well_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_output_well_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_output_well
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_output_well_audit();
CREATE TABLE audit.well_accepted_override (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
accepted boolean,
created_by_id integer,
created_at timestamp without time zone
);
GRANT SELECT ON audit.well_accepted_override TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.well_accepted_override TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_well_accepted_override_audit()
RETURNS TRIGGER AS $well_accepted_override_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_accepted_override SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_accepted_override SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_accepted_override SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_accepted_override_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_accepted_override_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_accepted_override
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_accepted_override_audit();
CREATE TABLE audit.plates (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
name text,
description text,
type_id text,
created_by_id integer,
created_at timestamp without time zone
);
GRANT SELECT ON audit.plates TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.plates TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_plates_audit()
RETURNS TRIGGER AS $plates_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.plates SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.plates SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.plates SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$plates_audit$ LANGUAGE plpgsql;
CREATE TRIGGER plates_audit
AFTER INSERT OR UPDATE OR DELETE ON public.plates
    FOR EACH ROW EXECUTE PROCEDURE public.process_plates_audit();
CREATE TABLE audit.process_input_well (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
well_id integer
);
GRANT SELECT ON audit.process_input_well TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_input_well TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_input_well_audit()
RETURNS TRIGGER AS $process_input_well_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_input_well SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_input_well SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_input_well SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_input_well_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_input_well_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_input_well
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_input_well_audit();
CREATE TABLE audit.wells (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
plate_id integer,
name text,
created_by_id integer,
created_at timestamp without time zone,
assay_pending timestamp without time zone,
assay_complete timestamp without time zone,
accepted boolean
);
GRANT SELECT ON audit.wells TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.wells TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_wells_audit()
RETURNS TRIGGER AS $wells_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.wells SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.wells SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.wells SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$wells_audit$ LANGUAGE plpgsql;
CREATE TRIGGER wells_audit
AFTER INSERT OR UPDATE OR DELETE ON public.wells
    FOR EACH ROW EXECUTE PROCEDURE public.process_wells_audit();
CREATE TABLE audit.process_design (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
design_id integer
);
GRANT SELECT ON audit.process_design TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_design TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_design_audit()
RETURNS TRIGGER AS $process_design_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_design SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_design SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_design SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_design_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_design_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_design
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_design_audit();
CREATE TABLE audit.process_cassette (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
cassette text
);
GRANT SELECT ON audit.process_cassette TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_cassette TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_cassette_audit()
RETURNS TRIGGER AS $process_cassette_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_cassette SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_cassette SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_cassette SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_cassette_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_cassette_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_cassette
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_cassette_audit();
CREATE TABLE audit.process_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.process_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_types_audit()
RETURNS TRIGGER AS $process_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_types_audit();
CREATE TABLE audit.processes (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
type_id text
);
GRANT SELECT ON audit.processes TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.processes TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_processes_audit()
RETURNS TRIGGER AS $processes_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.processes SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.processes SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.processes SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$processes_audit$ LANGUAGE plpgsql;
CREATE TRIGGER processes_audit
AFTER INSERT OR UPDATE OR DELETE ON public.processes
    FOR EACH ROW EXECUTE PROCEDURE public.process_processes_audit();
CREATE TABLE audit.process_bac (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
bac_plate text,
bac_clone_id integer
);
GRANT SELECT ON audit.process_bac TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_bac TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_bac_audit()
RETURNS TRIGGER AS $process_bac_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_bac SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_bac SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_bac SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_bac_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_bac_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_bac
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_bac_audit();
CREATE TABLE audit.plate_comments (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
plate_id integer,
comment_text text,
created_by_id integer,
created_at timestamp without time zone
);
GRANT SELECT ON audit.plate_comments TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.plate_comments TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_plate_comments_audit()
RETURNS TRIGGER AS $plate_comments_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.plate_comments SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.plate_comments SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.plate_comments SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$plate_comments_audit$ LANGUAGE plpgsql;
CREATE TRIGGER plate_comments_audit
AFTER INSERT OR UPDATE OR DELETE ON public.plate_comments
    FOR EACH ROW EXECUTE PROCEDURE public.process_plate_comments_audit();

CREATE TABLE audit.well_recombineering_results (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
pcr_u text,
pcr_d text,
pcr_g text,
rec_u text,
rec_d text,
rec_g text,
rec_ns text,
rec_result text
);
GRANT SELECT ON audit.well_recombineering_results TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.well_recombineering_results TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_well_recombineering_results_audit()
RETURNS TRIGGER AS $well_recombineering_results_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_recombineering_results SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_recombineering_results SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_recombineering_results SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_recombineering_results_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_recombineering_results_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_recombineering_results
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_recombineering_results_audit();

CREATE TABLE audit.well_comments (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
well_id integer,
comment_text text,
created_by_id integer,
created_at timestamp without time zone
);
GRANT SELECT ON audit.well_comments TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.well_comments TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_well_comments_audit()
RETURNS TRIGGER AS $well_comments_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_comments SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_comments SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_comments SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_comments_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_comments_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_comments
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_comments_audit();
