INSERT INTO amplicon_types(id) VALUES ('WT');
INSERT INTO amplicon_types(id) VALUES ('HDR');
update cell_lines set species_id = 'Mouse' where id in (1,2,3,8,9);
