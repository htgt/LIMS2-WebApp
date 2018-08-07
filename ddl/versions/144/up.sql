CREATE TABLE programmes (
  id INT PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE lab_heads (
  id INT PRIMARY KEY,
  name TEXT NOT NULL
);

ALTER TABLE projects ADD COLUMN programme_id INT;
ALTER TABLE projects ADD COLUMN lab_head_id INT;
ALTER TABLE projects ADD COLUMN requester_id TEXT;

ALTER TABLE projects
  ADD CONSTRAINT programmes_projects_fkey FOREIGN KEY (programme_id)
      REFERENCES programmes (id)
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE projects
  ADD CONSTRAINT lab_heads_projects_fkey FOREIGN KEY (lab_head_id)
      REFERENCES lab_heads (id)
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE projects
  ADD CONSTRAINT requesetrs_projects_fkey FOREIGN KEY (requester_id)
      REFERENCES requesters (id)
      ON UPDATE CASCADE ON DELETE CASCADE;

