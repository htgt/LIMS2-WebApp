INSERT INTO schema_versions(version) VALUES (144);

INSERT INTO programmes (id, abbr) VALUES ('Human Genetics', 'HG');
INSERT INTO programmes (id, abbr) VALUES ('Cellular Genetics', 'CG');
INSERT INTO programmes (id, abbr) VALUES ('Parasites and Microbes', 'PM');
INSERT INTO programmes (id, abbr) VALUES ('Cancer Ageing and Somatic Mutation', 'CASM');
INSERT INTO programmes (id, abbr) VALUES ('Other', 'Other');

INSERT INTO lab_heads (id) VALUES ('Andrew Bassett');
INSERT INTO lab_heads (id) VALUES ('Matthew Hurles');
INSERT INTO lab_heads (id) VALUES ('Daniel Gaffney');
INSERT INTO lab_heads (id) VALUES ('Serena Nik-Zainal');
INSERT INTO lab_heads (id) VALUES ('Nicholas Thompson');
INSERT INTO lab_heads (id) VALUES ('Antonio Vidal-Puig');
INSERT INTO lab_heads (id) VALUES ('Ludovic Vallier');
INSERT INTO lab_heads (id) VALUES ('David Adams');
INSERT INTO lab_heads (id) VALUES ('Robert Hancock');
INSERT INTO lab_heads (id) VALUES ( 'Other');

INSERT INTO requesters (id) VALUES ('meh@sanger.ac.uk');

INSERT INTO sponsors (id, description, abbr) VALUES ('NeuroMut', 'Human neuronal mutation genes for Daniel Gaffney', 'NEU');
INSERT INTO sponsors (id, description, abbr) VALUES ('Pancreatic Genetics', 'Human pancreatic progenitor genes for Ludovic Vallier', 'PAN');
INSERT INTO sponsors (id, description, abbr) VALUES ('StemBAT', 'Human genes in brown adipose tissue for Toni Vidal-Puig', 'SBAT');
INSERT INTO sponsors (id, description, abbr) VALUES ('Pathogen BH', 'Human pathogen response genes for Robert Hancock', 'PBH');
INSERT INTO sponsors (id, description, abbr) VALUES ('Pathogen NT', 'Human pathogen response genes for Nick Thompson', 'PNT');

ALTER TABLE project_sponsors DISABLE TRIGGER project_sponsors_audit;

UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9133 and sponsor_id = 'Cellular Genetics';

UPDATE project_sponsors SET sponsor_id = 'Pancreatic Genetics' where project_id = 9141 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'Pancreatic Genetics' where project_id = 9142 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'Pancreatic Genetics' where project_id = 9143 and sponsor_id = 'Cellular Genetics';

UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9279 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9306 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9307 and sponsor_id = 'Cellular Genetics';

UPDATE project_sponsors SET sponsor_id = 'Pancreatic Genetics' where project_id = 9308 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'Pancreatic Genetics' where project_id = 9309 and sponsor_id = 'Cellular Genetics';

UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9339 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9340 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9341 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9342 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9343 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9344 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9345 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9346 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9347 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9348 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9349 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'NeuroMut' where project_id = 9350 and sponsor_id = 'Cellular Genetics';

UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9416 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9417 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9418 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9419 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9420 and sponsor_id = 'Cellular Genetics';
UPDATE project_sponsors SET sponsor_id = 'StemBAT' where project_id = 9421 and sponsor_id = 'Cellular Genetics';

UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8747 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8792 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8797 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8799 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8800 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8803 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8807 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8808 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8810 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8813 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen BH' where project_id = 8821 and sponsor_id = 'Pathogen';

UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9269 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9282 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9298 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9299 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9300 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9301 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9302 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9303 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9304 and sponsor_id = 'Pathogen';

UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9326 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9327 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9332 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9335 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9336 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9337 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9400 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9401 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9402 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9403 and sponsor_id = 'Pathogen';

UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9404 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9405 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9406 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9407 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9408 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9409 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9410 and sponsor_id = 'Pathogen';

UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9412 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9413 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9414 and sponsor_id = 'Pathogen';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9415 and sponsor_id = 'Pathogen';

UPDATE project_sponsors SET sponsor_id = 'Test' where project_id = 8787 and sponsor_id = 'Stem Cell Engineering';

UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9268 and sponsor_id = 'Stem Cell Engineering';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9271 and sponsor_id = 'Stem Cell Engineering';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9288 and sponsor_id = 'Stem Cell Engineering';
UPDATE project_sponsors SET sponsor_id = 'Pathogen NT' where project_id = 9295 and sponsor_id = 'Stem Cell Engineering';

UPDATE project_sponsors SET sponsor_id = 'Test' where project_id = 9296 and sponsor_id = 'Stem Cell Engineering';
UPDATE project_sponsors SET sponsor_id = 'Test' where project_id = 9297 and sponsor_id = 'Stem Cell Engineering';
UPDATE project_sponsors SET sponsor_id = 'Test' where project_id = 9333 and sponsor_id = 'Stem Cell Engineering';
UPDATE project_sponsors SET sponsor_id = 'Test' where project_id = 9334 and sponsor_id = 'Stem Cell Engineering';


UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9187 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9190 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9192 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9193 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9194 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9196 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9198 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9199 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9201 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9202 and sponsor_id = 'Test';
UPDATE project_sponsors SET sponsor_id = 'Experimental Cancer Genetics' where project_id = 9203 and sponsor_id = 'Test';

UPDATE project_sponsors SET programme_id = 'Cellular Genetics', lab_head_id = 'Daniel Gaffney' where sponsor_id = 'NeuroMut' and project_id in (
9133, 9339, 9340, 9341, 9342, 9343, 9344, 9345, 9346, 9347, 9348, 9349, 9350
);

UPDATE project_sponsors SET programme_id = 'Cellular Genetics', lab_head_id = 'Ludovic Vallier' where sponsor_id = 'Pancreatic Genetics' and project_id in (
9141, 9142, 9143, 9308, 9309
);

UPDATE project_sponsors SET programme_id = 'Cellular Genetics', lab_head_id = 'Antonio Vidal-Puig' where sponsor_id = 'StemBAT' and project_id in (
9279, 9306, 9307, 9416, 9417, 9418, 9419, 9420, 9421
);

UPDATE project_sponsors SET programme_id = 'Human Genetics', lab_head_id = 'Matthew Hurles' where sponsor_id = 'Decipher';

UPDATE project_sponsors SET programme_id = 'Parasites and Microbes', lab_head_id = 'Robert Hancock' where sponsor_id = 'Pathogen BH' and project_id in (
8792, 8797, 8799, 8800, 8803, 8807, 8808, 8810, 8813, 8821
);

UPDATE project_sponsors SET programme_id = 'Parasites and Microbes', lab_head_id = 'Nicholas Thompson' where sponsor_id = 'Pathogen NT' and project_id in (
9269, 9282, 9298, 9299, 9300, 9301, 9302, 9303, 9304, 9326, 9327, 9332, 9335, 9336, 9337, 9400, 9401, 9402, 9403, 9404, 9405, 9406, 9407, 9408, 9409, 9410, 9412, 9413, 9414, 9415, 9268, 9271, 9288, 9295
);

UPDATE project_sponsors SET programme_id = 'Cancer Ageing and Somatic Mutation', lab_head_id = 'David Adams' where sponsor_id = 'Experimental Cancer Genetics' and project_id in (
9270, 9274, 9289, 9305, 9321, 9324, 9338, 9188, 9189, 9191, 9195, 9197, 9187, 9190, 9192, 9193, 9194, 9196, 9198, 9199, 9201, 9202, 9203
);

UPDATE project_sponsors SET programme_id = 'Cancer Ageing and Somatic Mutation', lab_head_id = 'Serena Nik-Zainal' where sponsor_id = 'Mutation' and project_id in (
9319, 9320, 9374, 9375
);

UPDATE project_sponsors SET programme_id = 'Other', lab_head_id = 'Andrew Bassett' where sponsor_id = 'Test' and project_id in (
8787, 9296, 9297, 9333, 9334
);

ALTER TABLE project_sponsors ENABLE TRIGGER project_sponsors_audit;
