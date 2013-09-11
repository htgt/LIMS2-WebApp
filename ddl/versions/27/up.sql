DROP TABLE IF EXISTS public.mutation_design_types;
CREATE TABLE public.mutation_design_types (
     mutation_id text,
     design_type text,
     PRIMARY KEY (mutation_id, design_type)
);
GRANT SELECT ON mutation_design_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON mutation_design_types TO "[% rw_role %]";

