ALTER TABLE plates ADD COLUMN barcode TEXT;

CREATE TABLE well_barcodes (
       well_id      INTEGER PRIMARY KEY REFERENCES wells(id),
       barcode      VARCHAR(40) NOT NULL UNIQUE
);
