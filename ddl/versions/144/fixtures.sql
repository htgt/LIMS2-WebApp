INSERT INTO schema_versions(version) VALUES (144);

INSERT INTO programmes (id, name) VALUES (1, 'Human Genetics');
INSERT INTO programmes (id, name) VALUES (2, 'Cellular Genetics');
INSERT INTO programmes (id, name) VALUES (3, 'Pathogen and Malaria');
INSERT INTO programmes (id, name) VALUES (4, 'Cancer Ageing and Somatic Mutation');

INSERT INTO lab_heads (id, name) VALUES (1, 'Matthew Hurles');
INSERT INTO lab_heads (id, name) VALUES (2, 'Nicholas Thomson');
INSERT INTO lab_heads (id, name) VALUES (3, 'Antonio Vidal-Puig');
INSERT INTO lab_heads (id, name) VALUES (4, 'Ludovic Vallier');
INSERT INTO lab_heads (id, name) VALUES (5, 'David Adams');
INSERT INTO lab_heads (id, name) VALUES (6, 'Bob Hancock');

INSERT INTO requesters (id) VALUES ('sc22@sanger.ac.uk');
INSERT INTO requesters (id) VALUES ('meh@sanger.ac.uk');

ALTER TABLE projects DISABLE TRIGGER projects_audit;

UPDATE projects SET programme_id = 2, lab_head_id = 4, requester_id = 'lv4@sanger.ac.uk' WHERE id = 9141;
UPDATE projects SET programme_id = 2, lab_head_id = 4, requester_id = 'lv4@sanger.ac.uk' WHERE id = 9142;
UPDATE projects SET programme_id = 2, lab_head_id = 4, requester_id = 'lv4@sanger.ac.uk' WHERE id = 9143;
UPDATE projects SET programme_id = 2, lab_head_id = 4, requester_id = 'lv4@sanger.ac.uk' WHERE id = 9308;
UPDATE projects SET programme_id = 2, lab_head_id = 4, requester_id = 'lv4@sanger.ac.uk' WHERE id = 9309;

UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'tvp@sanger.ac.uk' WHERE id = 9279;
UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'tvp@sanger.ac.uk' WHERE id = 9306;
UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'tvp@sanger.ac.uk' WHERE id = 9307;

UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'sc22@sanger.ac.uk' WHERE id = 9416;
UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'sc22@sanger.ac.uk' WHERE id = 9417;
UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'sc22@sanger.ac.uk' WHERE id = 9418;
UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'sc22@sanger.ac.uk' WHERE id = 9419;
UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'sc22@sanger.ac.uk' WHERE id = 9420;
UPDATE projects SET programme_id = 2, lab_head_id = 3, requester_id = 'sc22@sanger.ac.uk' WHERE id = 9421;

UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8978;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8981;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8984;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8985;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8987;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8982;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8983;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9134;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9135;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9136;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9137;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9138;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9139;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9140;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8979;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 8980;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9267;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9272;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9273;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9275;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9276;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9277;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9278;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9280;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9281;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9283;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9284;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9285;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9286;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9287;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9290;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9291;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9292;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9293;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9294;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9310;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9311;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9318;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9312;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9313;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9314;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9315;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9316;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9317;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9322;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9323;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9325;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9328;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9329;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9330;
UPDATE projects SET programme_id = 1, lab_head_id = 1, requester_id = 'meh@sanger.ac.uk' WHERE id = 9331;

ALTER TABLE projects ENABLE TRIGGER projects_audit;

