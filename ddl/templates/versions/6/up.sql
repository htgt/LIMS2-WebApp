-- Support for multiple species

CREATE TABLE species (
       id    TEXT PRIMARY KEY
);
GRANT SELECT ON species TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON species TO "[% rw_role %]";

CREATE TABLE audit.species (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id text
);
GRANT SELECT ON audit.species TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.species TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_species_audit()
RETURNS TRIGGER AS $species_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.species SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.species SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.species SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$species_audit$ LANGUAGE plpgsql;
CREATE TRIGGER species_audit
AFTER INSERT OR UPDATE OR DELETE ON public.species
    FOR EACH ROW EXECUTE PROCEDURE public.process_species_audit();

INSERT INTO species(id) VALUES ('Mouse'), ('Human');

-- Assemblies belong to a species
ALTER TABLE assemblies ADD COLUMN species_id TEXT REFERENCES species(id);

ALTER TABLE audit.assemblies ADD COLUMN species_id TEXT;

UPDATE assemblies SET species_id = 'Mouse';

ALTER TABLE assemblies ALTER COLUMN species_id SET NOT NULL;

-- A species has a default assembly
CREATE TABLE species_default_assembly (
       species_id   TEXT PRIMARY KEY REFERENCES species(id),
       assembly_id  TEXT NOT NULL REFERENCES assemblies(id)
);
GRANT SELECT ON species_default_assembly TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON species_default_assembly TO "[% rw_role %]";

CREATE TABLE audit.species_default_assembly (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
species_id text,
assembly_id text
);
GRANT SELECT ON audit.species_default_assembly TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.species_default_assembly TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_species_default_assembly_audit()
RETURNS TRIGGER AS $species_default_assembly_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.species_default_assembly SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.species_default_assembly SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.species_default_assembly SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$species_default_assembly_audit$ LANGUAGE plpgsql;
CREATE TRIGGER species_default_assembly_audit
AFTER INSERT OR UPDATE OR DELETE ON public.species_default_assembly
    FOR EACH ROW EXECUTE PROCEDURE public.process_species_default_assembly_audit();

INSERT INTO species_default_assembly(species_id,assembly_id)
VALUES('Mouse','NCBIM37');

-- BAC libraries belong to a species
ALTER TABLE bac_libraries ADD COLUMN species_id TEXT REFERENCES species(id);

ALTER TABLE audit.bac_libraries ADD COLUMN species_id TEXT;

UPDATE bac_libraries SET species_id = 'Mouse';

ALTER TABLE bac_libraries ALTER COLUMN species_id SET NOT NULL;

-- Chromosomes need a name and a species

CREATE TABLE new_chromosomes (
       id         SERIAL PRIMARY KEY,
       species_id TEXT NOT NULL REFERENCES species(id),
       name       TEXT NOT NULL,
       UNIQUE(species_id,name)
);
GRANT SELECT ON new_chromosomes TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON new_chromosomes TO "[% rw_role %]";
GRANT USAGE ON new_chromosomes_id_seq TO "[% rw_role %]";

CREATE TABLE audit.new_chromosomes (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
id integer,
species_id text,
name text
);
GRANT SELECT ON audit.new_chromosomes TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.new_chromosomes TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_new_chromosomes_audit()
RETURNS TRIGGER AS $new_chromosomes_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.new_chromosomes SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.new_chromosomes SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.new_chromosomes SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$new_chromosomes_audit$ LANGUAGE plpgsql;
CREATE TRIGGER new_chromosomes_audit
AFTER INSERT OR UPDATE OR DELETE ON public.new_chromosomes
    FOR EACH ROW EXECUTE PROCEDURE public.process_new_chromosomes_audit();

INSERT INTO new_chromosomes(species_id,name)
SELECT 'Mouse', id FROM chromosomes;

-- bac_clone_loci must link to new_chromosomes
ALTER TABLE bac_clone_loci RENAME COLUMN chr_id TO chr_name;
ALTER TABLE audit.bac_clone_loci RENAME COLUMN chr_id TO chr_name;

ALTER TABLE bac_clone_loci ADD COLUMN chr_id INTEGER REFERENCES new_chromosomes(id);
ALTER TABLE audit.bac_clone_loci ADD COLUMN chr_id INTEGER;
UPDATE bac_clone_loci SET chr_id = (SELECT id FROM new_chromosomes WHERE species_id = 'Mouse' AND name = chr_name);
ALTER TABLE bac_clone_loci ALTER COLUMN chr_id SET NOT NULL;
ALTER TABLE bac_clone_loci DROP COLUMN chr_name;
ALTER TABLE audit.bac_clone_loci DROP COLUMN chr_name;

-- design_oligo_loci must link to new_chromosomes
ALTER TABLE design_oligo_loci RENAME COLUMN chr_id TO chr_name;
ALTER TABLE audit.design_oligo_loci RENAME COLUMN chr_id TO chr_name;

ALTER TABLE design_oligo_loci ADD COLUMN chr_id INTEGER REFERENCES new_chromosomes(id);
ALTER TABLE audit.design_oligo_loci ADD COLUMN chr_id INTEGER;
UPDATE design_oligo_loci SET chr_id = (SELECT id FROM new_chromosomes WHERE species_id = 'Mouse' AND name = chr_name);
ALTER TABLE design_oligo_loci ALTER COLUMN chr_id SET NOT NULL;
ALTER TABLE design_oligo_loci DROP COLUMN chr_name;
ALTER TABLE audit.design_oligo_loci DROP COLUMN chr_name;

-- now we can dispense with the old chromosomes table and rename the new into place
DROP TABLE chromosomes;
DROP TABLE audit.chromosomes;

ALTER TABLE new_chromosomes RENAME TO chromosomes;
ALTER TABLE audit.new_chromosomes RENAME TO chromosomes;

CREATE OR REPLACE FUNCTION public.process_chromosomes_audit()
RETURNS TRIGGER AS $chromosomes_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.chromosomes SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.chromosomes SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.chromosomes SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$chromosomes_audit$ LANGUAGE plpgsql;
DROP TRIGGER chromosomes_audit ON public.chromosomes;
CREATE TRIGGER chromosomes_audit
AFTER INSERT OR UPDATE OR DELETE ON public.chromosomes
    FOR EACH ROW EXECUTE PROCEDURE public.process_chromosomes_audit();
DROP FUNCTION process_new_chromosomes_audit();

-- designs belong to a species
ALTER TABLE designs ADD COLUMN species_id TEXT REFERENCES species(id);
ALTER TABLE audit.designs ADD COLUMN species_id TEXT;
UPDATE designs SET species_id = 'Mouse';
ALTER TABLE designs ALTER COLUMN species_id SET NOT NULL;

-- plates belong to a species
ALTER TABLE plates ADD COLUMN species_id TEXT REFERENCES species(id);
ALTER TABLE audit.plates ADD COLUMN species_id TEXT;
UPDATE plates SET species_id = 'Mouse';
ALTER TABLE plates ALTER COLUMN species_id SET NOT NULL;

-- QC templates belong to a species
ALTER TABLE qc_templates ADD COLUMN species_id TEXT REFERENCES species(id);
ALTER TABLE audit.qc_templates ADD COLUMN species_id TEXT;
UPDATE qc_templates SET species_id = 'Mouse';
ALTER TABLE qc_templates ALTER COLUMN species_id SET NOT NULL;

-- QC sequencing projects belong to a species
ALTER TABLE qc_seq_projects ADD COLUMN species_id TEXT REFERENCES species(id);
ALTER TABLE audit.qc_seq_projects ADD COLUMN species_id TEXT;
UPDATE qc_seq_projects SET species_id = 'Mouse';
ALTER TABLE qc_seq_projects ALTER COLUMN species_id SET NOT NULL;

-- Store per-user default species in a preferences table
CREATE TABLE user_preferences (
       user_id            INTEGER PRIMARY KEY REFERENCES users(id),
       default_species_id TEXT NOT NULL REFERENCES species(id)
);
GRANT SELECT ON user_preferences TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON user_preferences TO "[% rw_role %]";

CREATE TABLE audit.user_preferences (
audit_op CHAR(1) NOT NULL CHECK (audit_op IN ('D','I','U')),
audit_user TEXT NOT NULL,
audit_stamp TIMESTAMP NOT NULL,
audit_txid INTEGER NOT NULL,
user_id integer,
default_species_id text
);
GRANT SELECT ON audit.user_preferences TO "[% ro_role %]";
GRANT SELECT,INSERT ON audit.user_preferences TO "[% rw_role %]";
CREATE OR REPLACE FUNCTION public.process_user_preferences_audit()
RETURNS TRIGGER AS $user_preferences_audit$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
           INSERT INTO audit.user_preferences SELECT 'D', user, now(), txid_current(), OLD.*;
        ELSIF (TG_OP = 'UPDATE') THEN
           INSERT INTO audit.user_preferences SELECT 'U', user, now(), txid_current(), NEW.*;
        ELSIF (TG_OP = 'INSERT') THEN
           INSERT INTO audit.user_preferences SELECT 'I', user, now(), txid_current(), NEW.*;
        END IF;
        RETURN NULL;
    END;
$user_preferences_audit$ LANGUAGE plpgsql;
CREATE TRIGGER user_preferences_audit
AFTER INSERT OR UPDATE OR DELETE ON public.user_preferences
    FOR EACH ROW EXECUTE PROCEDURE public.process_user_preferences_audit();

INSERT INTO user_preferences(user_id, default_species_id)
SELECT id, 'Mouse' FROM users;

INSERT INTO schema_versions(version) values(6);
