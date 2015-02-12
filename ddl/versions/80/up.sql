alter table projects drop constraint projects_recovery_class_fkey;

alter table project_recovery_class drop constraint project_recovery_class_pkey;
alter table project_recovery_class rename id to name;

alter table audit.project_recovery_class rename id to name;

ALTER TABLE project_recovery_class ADD COLUMN id SERIAL;

alter table audit.project_recovery_class add column id INT;

UPDATE project_recovery_class SET id = DEFAULT;
ALTER TABLE project_recovery_class ADD PRIMARY KEY (id);

alter table projects add column recovery_class_id INT;
alter table projects add foreign key (recovery_class_id) references project_recovery_class(id);

alter table audit.projects add column recovery_class_id INT;

UPDATE projects
SET recovery_class_id = project_recovery_class.id
FROM project_recovery_class
WHERE recovery_class = project_recovery_class.name;

alter table projects drop column recovery_class;
alter table audit.projects drop column recovery_class;