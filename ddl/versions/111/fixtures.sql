INSERT INTO schema_versions(version) VALUES (111);

UPDATE summaries SET dna_template = 'KOLF2' WHERE int_plate_name similar to 'HINT001[01235]';

UPDATE summaries SET dna_template = 'BOB' WHERE int_plate_name similar to 'HINT00(0|14)\S*';
