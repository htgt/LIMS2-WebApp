ALTER TABLE audit.projects ADD COLUMN cell_line_id integer;
ALTER TABLE audit.experiments DROP COLUMN project_id;
