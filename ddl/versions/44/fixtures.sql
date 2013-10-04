INSERT INTO schema_versions(version) VALUES (44);

INSERT INTO backbones (name, description) VALUES ( 'U6_BsaI_gRNA', 'mouse crispr vector' );

INSERT INTO cassettes ( name, promoter, phase_match_group, conditional, cre, resistance ) VALUES ( 'pL1L2IRESnEGFPOT2A_CreERT2bActNeo', 'true', 'pL1L2IRESnEGFPOT2A_CreERT2bActNeo', 'false', 'true', 'neo' );
