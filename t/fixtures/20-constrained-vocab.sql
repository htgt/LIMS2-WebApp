INSERT INTO assemblies(id)
VALUES ('NCBIM34'), ('NCBIM36'), ('NCBIM37');

INSERT INTO chromosomes (id)
VALUES ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'),
       ('10'), ('11'), ('12'), ('13'), ('14'), ('15'), ('16'),
       ('17'), ('18'), ('19'), ('X'), ('Y');

INSERT INTO bac_libraries (id) VALUES ('129'), ('black6');

INSERT INTO design_types(id)
VALUES ('conditional'), ('deletion'), ('insertion'), ('artificial-intron'), ('intron-replacement'), ('cre-bac');

INSERT INTO design_oligo_types(id)
VALUES ('G5'), ('U5'), ('U3'), ('D5'), ('D3'), ('G3');

INSERT INTO process_types(id,description)
VALUES ('create_di', 'Create design instance'),
       ('cre_bac_recom', 'Cre/BAC recombineering'),
       ('int_recom', 'Intermediate recombineering'),
       ('2w_gateway', 'Two-way gateway'),
       ('3w_gateway', 'Three-way gateway'),
       ('rearray', 'rearray wells'),
       ('dna_prep', 'dna prep'),
       ('recombinase', 'apply recombinase');

INSERT INTO recombinases(id)
VALUES ('Cre'),('Flp'),('Dre');

INSERT INTO plate_types(id,description)
VALUES ('DESIGN', 'Design Instances'),
       ('INT', 'Intermediate Vectors' ),
       ('POSTINT', 'Post-intermediate Vectors' ),
       ('FINAL', 'Final Vectors' ),
       ('CREBAC', 'Cre/BAC Vectors' ),
       ('DNA', 'DNA QC' );
