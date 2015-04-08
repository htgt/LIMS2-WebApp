ALTER TABLE audit.projects ADD COLUMN targeting_profile_id text;
CREATE TABLE audit.targeting_profiles (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
CREATE OR REPLACE FUNCTION public.process_targeting_profiles_audit()
RETURNS TRIGGER AS $targeting_profiles_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.targeting_profiles SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.targeting_profiles SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.targeting_profiles SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$targeting_profiles_audit$ LANGUAGE plpgsql;
CREATE TRIGGER targeting_profiles_audit
AFTER INSERT OR UPDATE OR DELETE ON public.targeting_profiles
    FOR EACH ROW EXECUTE PROCEDURE public.process_targeting_profiles_audit();
CREATE TABLE audit.targeting_profile_alleles (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
targeting_profile_id text,
allele_type text,
cassette_function text,
mutation_type text
);
CREATE OR REPLACE FUNCTION public.process_targeting_profile_alleles_audit()
RETURNS TRIGGER AS $targeting_profile_alleles_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.targeting_profile_alleles SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.targeting_profile_alleles SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.targeting_profile_alleles SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$targeting_profile_alleles_audit$ LANGUAGE plpgsql;
CREATE TRIGGER targeting_profile_alleles_audit
AFTER INSERT OR UPDATE OR DELETE ON public.targeting_profile_alleles
    FOR EACH ROW EXECUTE PROCEDURE public.process_targeting_profile_alleles_audit();
DROP TABLE audit.project_alleles;
