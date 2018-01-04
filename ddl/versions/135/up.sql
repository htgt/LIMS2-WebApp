create table project_experiment (
id  SERIAL PRIMARY KEY,
project_id INT REFERENCES projects(id),
experiment_id INT REFERENCES experiments(id)
);
