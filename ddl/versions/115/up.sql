CREATE TABLE design_append_aliases (
    design_type text REFERENCES design_types(id),
    alias text 
);
