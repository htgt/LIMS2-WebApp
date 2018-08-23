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
INSERT INTO lab_heads (id) VALUES ('Nicholas Thomson');
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


ALTER TABLE project_sponsors ENABLE TRIGGER project_sponsors_audit;
