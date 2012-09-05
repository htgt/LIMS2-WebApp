CREATE TABLE cell_lines (
       id          SERIAL PRIMARY KEY,
       name        TEXT NOT NULL DEFAULT ''
);
GRANT SELECT ON cell_lines TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON cell_lines TO "[% rw_role %]";


INSERT INTO cell_lines (name) 
SELECT DISTINCT cell_line 
FROM process_cell_line;

ALTER TABLE process_cell_line
ADD COLUMN cell_line_id INTEGER;

ALTER TABLE process_cell_line
ADD FOREIGN KEY (cell_line_id) REFERENCES cell_lines(id);

ALTER TABLE audit.process_cell_line
ADD COLUMN cell_line_id INTEGER;

ALTER TABLE audit.process_cell_line
ADD FOREIGN KEY (cell_line_id) REFERENCES cell_lines(id);

UPDATE process_cell_line
SET cell_line_id = id
FROM cell_lines
WHERE cell_line = cell_lines.name;

ALTER TABLE process_cell_line
DROP COLUMN cell_line;

ALTER TABLE audit.process_cell_line
DROP COLUMN cell_line;