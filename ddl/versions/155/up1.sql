CREATE TABLE amplicon_types (
    id TEXT PRIMARY KEY
);

CREATE TABLE amplicons (
    id SERIAL PRIMARY KEY,
    amplicon_type TEXT NOT NULL REFERENCES amplicon_types(id),
    seq TEXT NOT NULL
);

CREATE TABLE design_amplicons (
    design_id INTEGER NOT NULL REFERENCES designs(id),
    amplicon_id INTEGER PRIMARY KEY REFERENCES amplicons(id)
);

CREATE TABLE amplicon_loci (
    amplicon_id INTEGER PRIMARY KEY REFERENCES amplicons(id),
    chr_start INTEGER NOT NULL,
    chr_end INTEGER NOT NULL CHECK (chr_start <= chr_end),
    chr_strand INTEGER NOT NULL CHECK ( chr_strand = ANY (ARRAY[1, (-1)]) ),
    chr_id INTEGER NOT NULL REFERENCES chromosomes(id),
    assembly_id TEXT NOT NULL REFERENCES assemblies(id)
);