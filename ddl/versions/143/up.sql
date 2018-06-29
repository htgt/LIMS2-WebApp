CREATE TABLE hdr_template (
    id SERIAL PRIMARY KEY,
    design_id INTEGER references designs(id) NOT NULL,
    template TEXT NOT NULL
);
