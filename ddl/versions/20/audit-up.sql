CREATE TABLE audit.well_targeting_puro_pass (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
well_id integer,
result text,
created_at timestamp without time zone,
created_by_id integer
);
GRANT SELECT ON audit.well_targeting_puro_pass TO [% ro_role %];
GRANT SELECT,INSERT ON audit.well_targeting_puro_pass TO [% rw_role %];
CREATE OR REPLACE FUNCTION public.process_well_targeting_puro_pass_audit()
RETURNS TRIGGER AS $well_targeting_puro_pass_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.well_targeting_puro_pass SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.well_targeting_puro_pass SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.well_targeting_puro_pass SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$well_targeting_puro_pass_audit$ LANGUAGE plpgsql;
CREATE TRIGGER well_targeting_puro_pass_audit
AFTER INSERT OR UPDATE OR DELETE ON public.well_targeting_puro_pass
    FOR EACH ROW EXECUTE PROCEDURE public.process_well_targeting_puro_pass_audit();
