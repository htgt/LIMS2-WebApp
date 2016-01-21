ALTER TABLE audit.project_sponsors ADD COLUMN priority text;

ALTER TABLE audit.projects DROP COLUMN priority;