INSERT INTO schema_versions(version) VALUES (98);

INSERT INTO crispr_damage_types( id, description ) VALUES ( 'splice_acceptor', 'A splice variant that changes the 2 base region at the 3'' end of an intron' );
INSERT INTO crispr_damage_types( id, description ) VALUES ( 'splice_donor', 'A splice variant that changes the 2 base region at the 5'' end of an intron' );
INSERT INTO crispr_damage_types( id, description ) VALUES ( 'intron', 'A transcript variant occurring within an intron' );
