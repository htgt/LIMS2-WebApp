INSERT INTO schema_versions(version) VALUES (132);

INSERT INTO plate_types VALUES ('MISEQ','MiSEQ QC Plate');

INSERT INTO process_types VALUES ('miseq_oligo','Create miseq plate with oligo for HDR events');
INSERT INTO process_types VALUES ('miseq_vector','Create miseq plate with vector for HDR events');
INSERT INTO process_types VALUES ('miseq_no_template','Create miseq plate for analysis of NHEJ events only');
INSERT INTO process_types VALUES ('miseq','Create miseq plate from FP wells');
