INSERT INTO schema_versions(version)
VALUES (5);

INSERT INTO plate_types(id)
VALUES ('DESIGN'),('PCS'),('PGS'),('DNA'),('EP'),('EPD'),('FP'),('CREBAC');

INSERT INTO process_types(id,description)
VALUES ('create_di', 'Create design instance'),
       ('cre_bac_recom', 'Cre/BAC recombineering'),
       ('int_recom', 'Intermediate recombineering'),
       ('2w_gateway', 'Two-way gateway' ),
       ('3w_gateway', 'Three-way gateway' );
