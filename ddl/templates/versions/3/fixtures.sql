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

INSERT INTO design_comment_categories(name)
 VALUES ('Alternative variant not targeted'),
        ('NMD rescue'),
        ('Possible reinitiation'),
        ('Non protein coding locus'),
        ('Conserved elements'),
        ('Recovery design'),
        ('No NMD'),
        ('Other'),
        ('No BACs available'),
        ('Warning!'),
        ('Upstream domain unaffected'),
        ('Overlapping locus');      

INSERT INTO genotyping_primer_types(id)
VALUES ('GF1'), ('GF2'), ('GF3'), ('GF4'),
       ('GR1'), ('GR2'), ('GR3'), ('GR4'),
       ('LF1'), ('LF2'), ('LF3'),
       ('LR1'), ('LR2'), ('LR3'),
       ('PNFLR1'), ('PNFLR2'), ('PNFLR3'),
       ('EX3'), ('EX32'), ('EX5'), ('EX52');
