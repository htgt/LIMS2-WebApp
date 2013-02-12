ALTER TABLE projects ADD COLUMN gene_id text;
ALTER TABLE projects ADD COLUMN targeting_type text not null DEFAULT 'unknown';
 
DROP TABLE project_information;
