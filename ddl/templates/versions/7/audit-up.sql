CREATE TABLE audit.colony_count_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.colony_count_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.colony_count_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_colony_count_types_audit()
RETURNS TRIGGER AS $colony_count_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.colony_count_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.colony_count_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.colony_count_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$colony_count_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER colony_count_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.colony_count_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_colony_count_types_audit();
CREATE TABLE audit.process_cell_line (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
process_id integer,
cell_line text
);
GRANT SELECT ON audit.process_cell_line TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.process_cell_line TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_process_cell_line_audit()
RETURNS TRIGGER AS $process_cell_line_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.process_cell_line SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.process_cell_line SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.process_cell_line SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$process_cell_line_audit$ LANGUAGE plpgsql;
CREATE TRIGGER process_cell_line_audit
AFTER INSERT OR UPDATE OR DELETE ON public.process_cell_line
    FOR EACH ROW EXECUTE PROCEDURE public.process_process_cell_line_audit();
CREATE TABLE audit.well_primer_bands (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
primer_band_type_id text,
pass boolean,
created_at timestamp without time zone,
created_by_id integer
);
GRANT SELECT ON audit.well_primer_bands TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.well_primer_bands TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_well_primer_bands_audit()
RETURNS TRIGGER AS $well_primer_bands_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_primer_bands SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_primer_bands SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_primer_bands SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_primer_bands_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_primer_bands_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_primer_bands
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_primer_bands_audit();
CREATE TABLE audit.primer_band_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.primer_band_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.primer_band_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_primer_band_types_audit()
RETURNS TRIGGER AS $primer_band_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.primer_band_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.primer_band_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.primer_band_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$primer_band_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER primer_band_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.primer_band_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_primer_band_types_audit();
CREATE TABLE audit.well_colony_counts (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
colony_count_type_id text,
colony_count integer,
created_at timestamp without time zone,
created_by_id integer
);
GRANT SELECT ON audit.well_colony_counts TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.well_colony_counts TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_well_colony_counts_audit()
RETURNS TRIGGER AS $well_colony_counts_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_colony_counts SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_colony_counts SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_colony_counts SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_colony_counts_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_colony_counts_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_colony_counts
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_colony_counts_audit();
