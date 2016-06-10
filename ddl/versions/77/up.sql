CREATE TABLE fp_picking_list (
	id SERIAL PRIMARY KEY,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fp_picking_list_well_barcode (
    fp_picking_list_id INT REFERENCES fp_picking_list(id),
    well_barcode TEXT REFERENCES well_barcodes(barcode),
    picked BOOLEAN,
    PRIMARY KEY (fp_picking_list_id, well_barcode)
);
