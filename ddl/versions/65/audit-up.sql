ALTER TABLE audit.plates ADD COLUMN sponsor_id TEXT REFERENCES sponsors(id);

