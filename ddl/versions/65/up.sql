ALTER TABLE plates ADD COLUMN sponsor_id TEXT REFERENCES sponsors(id);
ALTER TABLE summaries ADD COLUMN sponsor_id TEXT;

