CREATE TABLE pipelines (
    id text PRIMARY KEY
);

ALTER TABLE user_preferences 
ADD COLUMN default_pipeline_id text references pipelines(id); 

