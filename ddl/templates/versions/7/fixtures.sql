INSERT INTO plate_types(id,description)
VALUES ('EP', 'Electroporation'),
       ('EP_PICK', 'ES Cells' ),
       ('XEP', 'Electroporation With Recombinase Applied' ),
       ('XEP_PICK', 'ES Cells With Recombinase Applied' ),
       ('XEP_POOL', 'ES Cells Backup Vial' ),
       ('SEP', 'Second Allele Electroporation' ),
       ('SEP_PICK', 'Second Allele ES Cells' ),
       ('SEP_POOL', 'Second Allele Backup Vial' ),
       ('SFP', 'Second Allele Freezer Plates' ),
       ('FP', 'Freezer Plates' );

INSERT INTO process_types(id,description)
VALUES ('clone_pick', 'Pick from EP plate'),
       ('clone_pool', 'Pool es cells into backup vial'),
       ('first_electroporation', 'First (standard) electroporation'),
       ('second_electroporation', 'Second electroporation in double targetted cells'),
       ('freeze', 'Create freezer plate well');

INSERT INTO primer_band_types(id)
VALUES ('gr1'),
       ('gr2'),
       ('gr3'),
       ('gr4'),
       ('gf1'),
       ('gf2'),
       ('gf3'),
       ('gf4'),
       ('tr_pcr');

INSERT INTO colony_count_types(id)
VALUES ('blue_colonies'), 
       ('white_colonies'),
       ('picked_colonies'),
       ('total_colonies'),
       ('remaining_unstained_colonies'); 
