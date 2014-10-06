ALTER TABLE projects ADD COLUMN recovery_class TEXT DEFAULT NULL;
ALTER TABLE projects ADD COLUMN recovery_comment TEXT DEFAULT NULL;
ALTER TABLE projects ADD CONSTRAINT null_recovery CHECK(recovery_class IS NOT NULL OR recovery_comment IS NULL);

