CREATE TABLE audit.mutation_design_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
mutation_id text,
design_type text
);
GRANT SELECT ON audit.mutation_design_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.mutation_design_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_mutation_design_types_audit()
RETURNS TRIGGER AS $mutation_design_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.mutation_design_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.mutation_design_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.mutation_design_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$mutation_design_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER mutation_design_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.mutation_design_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_mutation_design_types_audit();
