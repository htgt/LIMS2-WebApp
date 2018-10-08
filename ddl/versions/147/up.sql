CREATE TABLE well_t7 (
  well_id INT PRIMARY KEY REFERENCES wells(id),
  t7_score INT,
  t7_status BOOl default '0',
  created_by_id INT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
