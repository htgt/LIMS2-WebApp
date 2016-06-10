INSERT INTO schema_versions(version) VALUES (75);

INSERT INTO crispr_damage_types( id, description ) VALUES ( 'wild_type', 'wild type, no damage' );
INSERT INTO crispr_damage_types( id, description ) VALUES ( 'frameshift', 'Damage that causes a frameshift mutation' );
INSERT INTO crispr_damage_types( id, description ) VALUES ( 'in-frame', 'Damage that does not cause a frameshift mutation' );
INSERT INTO crispr_damage_types( id, description ) VALUES ( 'mosaic', 'Multiple types of damage' );
