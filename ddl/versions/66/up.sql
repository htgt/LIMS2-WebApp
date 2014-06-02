ALTER TABLE well_dna_quality ADD COLUMN egel_pass BOOLEAN;
ALTER TABLE well_dna_quality ALTER COLUMN quality DROP NOT NULL;
