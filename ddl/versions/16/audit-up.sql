CREATE TABLE audit.qc_template_well_recombinase (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_template_well_id integer,
recombinase_id text
);
GRANT SELECT ON audit.qc_template_well_recombinase TO [% ro_role %];
GRANT SELECT,INSERT ON audit.qc_template_well_recombinase TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_qc_template_well_recombinase_audit()
RETURNS TRIGGER AS $qc_template_well_recombinase_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_template_well_recombinase SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_template_well_recombinase SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_template_well_recombinase SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_template_well_recombinase_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_template_well_recombinase_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_template_well_recombinase
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_template_well_recombinase_audit();
CREATE TABLE audit.qc_template_well_backbone (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_template_well_id integer,
backbone_id integer
);
GRANT SELECT ON audit.qc_template_well_backbone TO [% ro_role %];
GRANT SELECT,INSERT ON audit.qc_template_well_backbone TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_qc_template_well_backbone_audit()
RETURNS TRIGGER AS $qc_template_well_backbone_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_template_well_backbone SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_template_well_backbone SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_template_well_backbone SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_template_well_backbone_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_template_well_backbone_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_template_well_backbone
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_template_well_backbone_audit();
CREATE TABLE audit.qc_template_well_cassette (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
qc_template_well_id integer,
cassette_id integer
);
GRANT SELECT ON audit.qc_template_well_cassette TO [% ro_role %];
GRANT SELECT,INSERT ON audit.qc_template_well_cassette TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_qc_template_well_cassette_audit()
RETURNS TRIGGER AS $qc_template_well_cassette_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.qc_template_well_cassette SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.qc_template_well_cassette SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.qc_template_well_cassette SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$qc_template_well_cassette_audit$ LANGUAGE plpgsql;
CREATE TRIGGER qc_template_well_cassette_audit
AFTER INSERT OR UPDATE OR DELETE ON public.qc_template_well_cassette
    FOR EACH ROW EXECUTE PROCEDURE public.process_qc_template_well_cassette_audit();
