CREATE TABLE audit.cached_reports (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id character(36),
report_class text,
params text,
expires timestamp without time zone
);
GRANT SELECT ON audit.cached_reports TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.cached_reports TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_cached_reports_audit()
RETURNS TRIGGER AS $cached_reports_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.cached_reports SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.cached_reports SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.cached_reports SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$cached_reports_audit$ LANGUAGE plpgsql;
CREATE TRIGGER cached_reports_audit
AFTER INSERT OR UPDATE OR DELETE ON public.cached_reports
    FOR EACH ROW EXECUTE PROCEDURE public.process_cached_reports_audit();
CREATE TABLE audit.targeting_type (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
targeting_type text
);
GRANT SELECT ON audit.targeting_type TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.targeting_type TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_targeting_type_audit()
RETURNS TRIGGER AS $targeting_type_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.targeting_type SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.targeting_type SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.targeting_type SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$targeting_type_audit$ LANGUAGE plpgsql;
CREATE TRIGGER targeting_type_audit
AFTER INSERT OR UPDATE OR DELETE ON public.targeting_type
    FOR EACH ROW EXECUTE PROCEDURE public.process_targeting_type_audit();
CREATE TABLE audit.mutation_type (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
mutation_type text
);
GRANT SELECT ON audit.mutation_type TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.mutation_type TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_mutation_type_audit()
RETURNS TRIGGER AS $mutation_type_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.mutation_type SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.mutation_type SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.mutation_type SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$mutation_type_audit$ LANGUAGE plpgsql;
CREATE TRIGGER mutation_type_audit
AFTER INSERT OR UPDATE OR DELETE ON public.mutation_type
    FOR EACH ROW EXECUTE PROCEDURE public.process_mutation_type_audit();
CREATE TABLE audit.final_cassette_function (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
final_cassette_function text
);
GRANT SELECT ON audit.final_cassette_function TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.final_cassette_function TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_final_cassette_function_audit()
RETURNS TRIGGER AS $final_cassette_function_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           
           INSERT INTO audit.final_cassette_function SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.final_cassette_function SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.final_cassette_function SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$final_cassette_function_audit$ LANGUAGE plpgsql;
CREATE TRIGGER final_cassette_function_audit
AFTER INSERT OR UPDATE OR DELETE ON public.final_cassette_function
    FOR EACH ROW EXECUTE PROCEDURE public.process_final_cassette_function_audit();
