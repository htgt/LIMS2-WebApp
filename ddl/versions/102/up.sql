/* Add cell line to project */
ALTER TABLE projects ADD COLUMN cell_line_id INTEGER REFERENCES cell_lines(id);

/* Re-link experiments to gene_id rather than project_id */
ALTER TABLE experiments ADD COLUMN gene_id TEXT;

ALTER TABLE audit.experiments ADD COLUMN gene_id text;

UPDATE experiments
SET gene_id = (
  SELECT projects.gene_id from projects
  WHERE projects.id = experiments.project_id
);

ALTER TABLE experiments DROP COLUMN project_id;

/* Now run migration script to add cell_line_ids to projects
and to create extra projects where more than one cell line
has been sponsored */

