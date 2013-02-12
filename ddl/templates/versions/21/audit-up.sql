CREATE TABLE audit.project_alleles (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
project_id integer,
allele_type text,
cassette_function text,
mutation_type text
);
GRANT SELECT ON audit.project_alleles TO [% ro_role %] ;
GRANT SELECT,INSERT ON audit.project_alleles TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_project_alleles_audit()
RETURNS TRIGGER AS $project_alleles_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.project_alleles SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.project_alleles SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.project_alleles SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$project_alleles_audit$ LANGUAGE plpgsql;
CREATE TRIGGER project_alleles_audit
AFTER INSERT OR UPDATE OR DELETE ON public.project_alleles
    FOR EACH ROW EXECUTE PROCEDURE public.process_project_alleles_audit();
CREATE TABLE audit.project_information (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
project_id integer,
gene_id text,
targeting_type text
);
GRANT SELECT ON audit.project_information TO [% ro_role %];
GRANT SELECT,INSERT ON audit.project_information TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_project_information_audit()
RETURNS TRIGGER AS $project_information_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.project_information SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.project_information SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.project_information SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$project_information_audit$ LANGUAGE plpgsql;
CREATE TRIGGER project_information_audit
AFTER INSERT OR UPDATE OR DELETE ON public.project_information
    FOR EACH ROW EXECUTE PROCEDURE public.process_project_information_audit();
CREATE TABLE audit.cassette_function (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
promoter boolean,
conditional boolean,
cre boolean,
well_has_cre boolean,
well_has_no_recombinase boolean
);
GRANT SELECT ON audit.cassette_function TO [% ro_role %];
GRANT SELECT,INSERT ON audit.cassette_function TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_cassette_function_audit()
RETURNS TRIGGER AS $cassette_function_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.cassette_function SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.cassette_function SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.cassette_function SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$cassette_function_audit$ LANGUAGE plpgsql;
CREATE TRIGGER cassette_function_audit
AFTER INSERT OR UPDATE OR DELETE ON public.cassette_function
    FOR EACH ROW EXECUTE PROCEDURE public.process_cassette_function_audit();

