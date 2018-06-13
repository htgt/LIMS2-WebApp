CREATE TABLE miseq_hdr_template (
    design_id INTEGER references designs(id) NOT NULL,
    template TEXT NOT NULL
);
