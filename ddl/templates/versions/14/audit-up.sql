
CREATE TABLE audit.well_genotyping_results (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
genotyping_result_type_id text,
call text,
copy_number double precision,
copy_number_range double precision,
confidence double precision,
created_at timestamp without time zone,
created_by_id integer
);
GRANT SELECT ON audit.well_genotyping_results TO [% ro_role %];
GRANT SELECT,INSERT ON audit.well_genotyping_results TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_well_genotyping_results_audit()
RETURNS TRIGGER AS $well_genotyping_results_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_genotyping_results SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_genotyping_results SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_genotyping_results SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_genotyping_results_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_genotyping_results_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_genotyping_results
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_genotyping_results_audit();
CREATE TABLE audit.genotyping_result_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.genotyping_result_types TO [% ro_role %];
GRANT SELECT,INSERT ON audit.genotyping_result_types TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_genotyping_result_types_audit()
RETURNS TRIGGER AS $genotyping_result_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.genotyping_result_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.genotyping_result_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.genotyping_result_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$genotyping_result_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER genotyping_result_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.genotyping_result_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_genotyping_result_types_audit();
