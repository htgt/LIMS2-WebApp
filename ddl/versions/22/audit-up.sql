ALTER TABLE audit.projects ADD COLUMN gene_id text;
ALTER TABLE audit.projects ADD COLUMN targeting_type text;
DROP TABLE audit.project_information;
