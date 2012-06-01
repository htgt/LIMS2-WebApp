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
