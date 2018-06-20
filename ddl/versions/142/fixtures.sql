INSERT INTO schema_versions(version) VALUES (142);
INSERT INTO pipelines VALUES ('pipeline_I');
INSERT INTO pipelines VALUES ('pipeline_II');

UPDATE user_preferences 
SET default_pipeline_id = 'pipeline_II'
WHERE 
default_pipeline_id IS NULL;

