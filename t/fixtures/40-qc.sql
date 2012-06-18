--
-- Minimal QC test data
--

INSERT INTO qc_templates(name) VALUES ('T001');
       
INSERT INTO qc_runs (id, created_by_id, profile, qc_template_id, software_version)
SELECT '3C41F49A-B6D6-11E1-8038-C8C8F7D1DA10', users.id, 'test', qc_templates.id, '0.001'
FROM users
CROSS JOIN qc_templates
WHERE users.name = 'test_user@example.org'
AND qc_templates.name = 'T001';
