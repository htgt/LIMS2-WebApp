DROP TABLE IF EXISTS hdr_template;
DROP TABLE IF EXISTS miseq_project_well_exp;
DROP TABLE IF EXISTS miseq_project_well;
ALTER TABLE miseq_experiment DROP COLUMN old_miseq_id;
DROP TABLE IF EXISTS miseq_projects;
