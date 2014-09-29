CREATE TABLE barcode_states (
    id TEXT PRIMARY key,
    description TEXT
);

ALTER TABLE well_barcodes ADD COLUMN barcode_state TEXT REFERENCES barcode_states(id);

CREATE TABLE barcode_event (
    id SERIAL PRIMARY KEY,
    barcode TEXT NOT NULL REFERENCES well_barcodes(barcode),
    old_state TEXT REFERENCES barcode_states(id),
    new_state TEXT REFERENCES barcode_states(id),
    old_well_id INT REFERENCES wells(id),
    new_well_id INT REFERENCES wells(id),
    comment TEXT,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
