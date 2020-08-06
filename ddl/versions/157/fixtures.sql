INSERT INTO schema_versions(version) VALUES(157);
INSERT INTO sponsors VALUES('Decipher2-WC10141', 'Human genes for Decipher Project Part2');
UPDATE project_sponsors SET sponsor_id='Decipher2-WC10141' WHERE sponsor_id='Decipher2_WC10141';
DELETE FROM sponsors WHERE id='Decipher2_WC10141';
UPDATE sponsors SET abbr='DDD2' WHERE id='Decipher2-WC10141';
