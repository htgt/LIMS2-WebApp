INSERT INTO schema_versions(version)
VALUES (5);

INSERT INTO plate_types(id)
VALUES ('DESIGN'),('PCS'),('PGS'),('DNA'),('EP'),('EPD'),('FP'),('CREBAC');

INSERT INTO process_types(id,description, plate_type_id)
VALUES ('create_di', 'Create design instance', 'DESIGN'),
       ('cre_bac_recom', 'Cre/BAC recombineering', 'CREBAC'),
       ('int_recom', 'Intermediate recombineering', 'PCS'),
       ('2w_gateway', 'Two-way gateway', 'PGS'),
       ('3w_gateway', 'Three-way gateway', 'PGS');
