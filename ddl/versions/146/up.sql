CREATE TABLE process_crispr_pair (
  process_id INT PRIMARY KEY REFERENCES processes(id),
  crispr_pair_id INT NOT NULL REFERENCES crispr_pairs(id)
);

CREATE TABLE process_crispr_group (
  process_id INT PRIMARY KEY REFERENCES processes(id),
  crispr_group_id INT NOT NULL REFERENCES crispr_groups(id)
);
