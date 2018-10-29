CREATE TABLE process_crispr_pair (
  process_id INT PRIMARY KEY REFERENCES processes(id),
  crispr_pair_id INT NOT NULL REFERENCES crispr_pairs(id)
);

CREATE TABLE process_crispr_group (
  process_id INT PRIMARY KEY REFERENCES processes(id),
  crispr_group_id INT NOT NULL REFERENCES crispr_groups(id)
);

CREATE TABLE well_t7 (
  well_id INT PRIMARY KEY REFERENCES wells(id),
  t7_score INT,
  t7_status TEXT,
  created_by_id INT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

