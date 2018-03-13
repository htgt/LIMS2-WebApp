CREATE TABLE guided_types (
  id INT PRIMARY KEY,
  name TEXT NOT NULL
);
CREATE TABLE process_guided_type (
  process_id INT PRIMARY KEY REFERENCES processes(id),
  guided_type_id INT NOT NULL REFERENCES guided_types(id)
);
