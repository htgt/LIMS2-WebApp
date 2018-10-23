CREATE TABLE programmes (
  id TEXT PRIMARY KEY,
  abbr TEXT NOT NULL
);

CREATE TABLE lab_heads (
  id TEXT PRIMARY KEY
);

ALTER TABLE project_sponsors ADD COLUMN programme_id TEXT;
ALTER TABLE project_sponsors ADD COLUMN lab_head_id TEXT;

ALTER TABLE project_sponsors DROP CONSTRAINT project_sponsors_key;

ALTER TABLE project_sponsors ADD FOREIGN KEY (programme_id) REFERENCES programmes(id);
ALTER TABLE project_sponsors ADD FOREIGN KEY (lab_head_id) REFERENCES lab_heads(id);

