CREATE TABLE programmes (
  id INT PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE lab_heads (
  id INT PRIMARY KEY,
  name TEXT NOT NULL
);

ALTER TABLE project_sponsors ADD COLUMN programme_name TEXT;
ALTER TABLE project_sponsors ADD COLUMN lab_head_name TEXT;

ALTER TABLE project_sponsors
  ADD CONSTRAINT programmes_project_sponsors_fkey FOREIGN KEY (programme_name)
      REFERENCES programmes (name)
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE project_sponsors
  ADD CONSTRAINT lab_heads_project_sponsors_fkey FOREIGN KEY (lab_head_name)
      REFERENCES lab_heads (name)
      ON UPDATE CASCADE ON DELETE CASCADE;

