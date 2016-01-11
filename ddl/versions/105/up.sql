ALTER TABLE designs ADD COLUMN parent_id integer REFERENCES designs(id);
