ALTER TABLE cell_lines ADD COLUMN species_id TEXT REFERENCES species(id) NOT NULL DEFAULT 'Human';
