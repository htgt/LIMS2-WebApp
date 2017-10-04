create table crispr_storage (
id  SERIAL PRIMARY KEY,
tube_location TEXT,
box_name TEXT,
created_on TIMESTAMP DEFAULT now(),
crispr_id INT REFERENCES crisprs(id),
created_by_user TEXT REFERENCES users(name),
stored_by_user TEXT REFERENCES users(name)
);
