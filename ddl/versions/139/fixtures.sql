INSERT INTO schema_versions(version) VALUES (138);

INSERT INTO miseq_design_presets(name, created_by, genomic_threshold, min_gc, max_gc, opt_gc, min_mt, max_mt, opt_mt) VALUES ('Default',432,30,40,60,50,57,63,60);
INSERT INTO miseq_primer_presets(preset_id, internal, search_width, offset_width, increment_value) VALUES (1,true,148,50,15);
INSERT INTO miseq_primer_presets(preset_id, internal, search_width, offset_width, increment_value) VALUES (1,false,350,148,50);
