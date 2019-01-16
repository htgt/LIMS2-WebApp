ALTER TABLE cell_lines ADD COLUMN origin_well text REFERENCES wells(id);
ALTER TABLE cell_lines ADD COLUMN description text;
