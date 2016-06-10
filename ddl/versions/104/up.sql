CREATE TABLE design_oligo_appends(
    id text NOT NULL,
    design_oligo_type_id text references design_oligo_types(id) NOT NULL,
    seq text NOT NULL
);


