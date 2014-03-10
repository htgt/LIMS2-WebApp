INSERT INTO nucleases(id, name)
VALUES ('1','test1'),
       ('2','test2'),
       ('3','test3'),
       ('4','test4');


DELETE FROM process_types where id='crispr_single_ep';
DELETE FROM process_types where id='crispr_paired_ep';

INSERT INTO process_types(id,description)
VALUES ('assembly_single','Single crispr assembly'),
       ('assembly_paired','Paired crispr assembly'),
       ('crispr_ep','Crispr electroporation');

INSERT INTO plate_types(id,description)
VALUES ('ASSEMBLY','Crispr assembly');

INSERT INTO schema_versions(version)
VALUES (55);

