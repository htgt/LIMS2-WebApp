INSERT INTO nucleases(id, name)
VALUES ('1','Cas9 Church D10A (+bsd)'),
       ('2','Cas9 ZF-NLS (WT)'),
       ('3','Cas9 ZF-H840A (-bsd)'),
       ('4','Cas9 ZF-D10A (-bsd)'),
       ('5','Cas9 Church WT'),
       ('6','Cas9 Protein Toolgen');


DELETE FROM process_types where id='crispr_single_ep';
DELETE FROM process_types where id='crispr_paired_ep';

INSERT INTO process_types(id,description)
VALUES ('single_crispr_assembly','Single crispr assembly'),
       ('paired_crispr_assembly','Paired crispr assembly'),
       ('crispr_ep','Crispr electroporation');

INSERT INTO plate_types(id,description)
VALUES ('ASSEMBLY','Crispr assembly');

INSERT INTO schema_versions(version)
VALUES (55);

