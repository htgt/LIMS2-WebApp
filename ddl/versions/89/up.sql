ALTER TABLE summaries ALTER COLUMN to_report SET DEFAULT true;
UPDATE summaries SET to_report = true WHERE to_report is null;
ALTER TABLE summaries ALTER COLUMN to_report SET NOT NULL;
