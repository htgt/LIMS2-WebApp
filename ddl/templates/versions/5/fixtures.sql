INSERT INTO schema_versions(version)
VALUES (5);

INSERT INTO plate_types(id,description)
VALUES ('DESIGN', 'Design Instances'),
       ('INT', 'Intermediate Vectors' ),
       ('POSTINT', 'Post-intermediate Vectors' ),
       ('FINAL', 'Final Vectors' ),
       ('CREBAC', 'Cre/BAC Vectors' ),
       ('DNA', 'DNA QC' );

INSERT INTO process_types(id,description)
VALUES ('create_di', 'Create design instance'),
       ('cre_bac_recom', 'Cre/BAC recombineering'),
       ('int_recom', 'Intermediate recombineering'),
       ('2w_gateway', 'Two-way gateway'),
       ('3w_gateway', 'Three-way gateway'),
       ('rearray', 'rearray wells'),
       ('recombinase', 'apply recombinase');

INSERT INTO recombinases(id)
VALUES ('Cre'),('Flp'),('Dre');
