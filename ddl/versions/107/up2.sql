UPDATE project_sponsors SET priority = (
	SELECT priority FROM projects where projects.id = project_sponsors.project_id
);

ALTER TABLE projects DROP COLUMN priority;
