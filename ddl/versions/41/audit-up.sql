ALTER TABLE audit.gene_design ADD COLUMN gene_type_id text;

CREATE TABLE audit.gene_types (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text,
description text,
local boolean
);
GRANT SELECT ON audit.gene_types TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.gene_types TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_gene_types_audit()
RETURNS TRIGGER AS $gene_types_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.gene_types SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.gene_types SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.gene_types SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$gene_types_audit$ LANGUAGE plpgsql;
CREATE TRIGGER gene_types_audit
AFTER INSERT OR UPDATE OR DELETE ON public.gene_types
    FOR EACH ROW EXECUTE PROCEDURE public.process_gene_types_audit();
