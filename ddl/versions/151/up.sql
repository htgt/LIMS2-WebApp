AlTER TABLE miseq_alleles_frequency
    ADD COLUMN reference_sequence text,
    ADD COLUMN quality_score text;
