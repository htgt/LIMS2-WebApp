CREATE TABLE dna_templates(
    id text PRIMARY KEY
);

ALTER TABLE summaries ADD COLUMN dna_template text REFERENCES dna_templates(id);

ALTER TABLE processes ADD COLUMN dna_template text REFERENCES dna_templates(id);
