ALTER TABLE audit.projects ADD COLUMN recovery_class TEXT DEFAULT NULL;
ALTER TABLE audit.projects ADD COLUMN recovery_comment TEXT DEFAULT NULL;
ALTER TABLE audit.projects ADD CONSTRAINT null_recovery CHECK(recovery_class IS NOT NULL OR recovery_comment IS NULL);

