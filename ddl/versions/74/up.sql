CREATE TABLE project_recovery_class (
    id                VARCHAR(64) PRIMARY KEY NOT NULL,
    description       TEXT
);
ALTER TABLE projects ADD COLUMN recovery_class TEXT DEFAULT NULL;
ALTER TABLE projects ADD COLUMN recovery_comment TEXT DEFAULT NULL REFERENCES project_recovery_class(id);
ALTER TABLE projects ADD CONSTRAINT null_recovery CHECK(recovery_class IS NOT NULL OR recovery_comment IS NULL);
ALTER TABLE projects ADD COLUMN priority TEXT DEFAULT NULL;
