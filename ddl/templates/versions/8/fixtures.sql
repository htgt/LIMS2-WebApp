INSERT INTO schema_versions(version)
VALUES (8);

INSERT INTO sponsors(id,description)
VALUES ('Core', 'Homozygous - Core'), 
       ('Syboss', 'Homozygous - Syboss'),
       ('Pathogens', 'Homozygous - Pathogens'),
       ('Cre Knockin', 'EUCOMMTools-Cre Knockin'),
       ('Cre BAC', 'EUCOMMTools-Cre BAC'),
       ('Human','Homozygous - Human');

INSERT INTO mutation_type(mutation_type)
VALUES ('conditional'),
       ('deletion'),
       ('insertion');

INSERT INTO targeting_type(targeting_type)
VALUES ('single_targeting'),
       ('double_targeting'),
       ('modified_bac_insertion');

INSERT INTO final_cassette_function(final_cassette_function)
VALUES ('knockout_first'),
       ('reporter_only'),
       ('conditional_only'),
       ('cre_expressor'),
       ('promoterless_cre_expressor');
