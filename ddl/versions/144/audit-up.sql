CREATE TABLE audit.miseq_alleles_frequency (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
miseq_well_experiment_id integer,
aligned_sequence text,
nhej boolean,
unmodified boolean,
hdr boolean,
n_deleted integer,
n_inserted integer,
n_mutated integer,
n_reads integer
);
CREATE OR REPLACE FUNCTION public.process_miseq_alleles_frequency_audit()
RETURNS TRIGGER AS $miseq_alleles_frequency_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.miseq_alleles_frequency SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.miseq_alleles_frequency SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.miseq_alleles_frequency SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$miseq_alleles_frequency_audit$ LANGUAGE plpgsql;
CREATE TRIGGER miseq_alleles_frequency_audit
AFTER INSERT OR UPDATE OR DELETE ON public.miseq_alleles_frequency
    FOR EACH ROW EXECUTE PROCEDURE public.process_miseq_alleles_frequency_audit();
ALTER TABLE audit.miseq_experiment ADD COLUMN nhej_reads integer;
ALTER TABLE audit.miseq_experiment ADD COLUMN hdr_reads integer;
ALTER TABLE audit.miseq_experiment ADD COLUMN mixed_reads integer;
ALTER TABLE audit.miseq_experiment DROP COLUMN mutation_reads;
ALTER TABLE audit.miseq_well_experiment ADD COLUMN total_reads integer;
CREATE TABLE audit.indel_distribution_graph (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
indel_size_distribution_graph bytea
);
CREATE OR REPLACE FUNCTION public.process_indel_distribution_graph_audit()
RETURNS TRIGGER AS $indel_distribution_graph_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.indel_distribution_graph SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.indel_distribution_graph SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.indel_distribution_graph SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$indel_distribution_graph_audit$ LANGUAGE plpgsql;
CREATE TRIGGER indel_distribution_graph_audit
AFTER INSERT OR UPDATE OR DELETE ON public.indel_distribution_graph
    FOR EACH ROW EXECUTE PROCEDURE public.process_indel_distribution_graph_audit();
