UPDATE user_preferences
    SET default_pipeline_id = 'pipeline_II'
    WHERE
        default_pipeline_id IS NULL;

