ALTER TABLE genotyping_primers ADD COLUMN tm NUMERIC(5,3), ADD COLUMN gc_content NUMERIC(5,3);
CREATE TABLE crispr_primer_types(
        primer_name         TEXT NOT NULL PRIMARY KEY
);
ALTER TABLE crispr_primer_types
  OWNER TO lims2;


CREATE TABLE crispr_primers (
        crispr_oligo_id      SERIAL PRIMARY KEY NOT NULL,
        crispr_pair_id       INTEGER REFERENCES crispr_pairs(id),
        crispr_id            INTEGER REFERENCES crisprs(id),
        primer_name          TEXT NOT NULL,
        primer_seq           TEXT NOT NULL,
        tm                   NUMERIC(5,3),
        gc_content           NUMERIC(5,3),
        CONSTRAINT "crispr primer name must belong to allowed list" FOREIGN KEY(primer_name)
          REFERENCES crispr_primer_types(primer_name) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION
);
ALTER TABLE crispr_primers
  OWNER TO lims2;


CREATE TABLE crispr_primers_loci(
        crispr_oligo_id     INTEGER NOT NULL,
        assembly_id         TEXT NOT NULL,
        chr_id              INTEGER NOT NULL,
        chr_start           INTEGER NOT NULL,
        chr_end             INTEGER NOT NULL,
        chr_strand          INTEGER NOT NULL,
        CONSTRAINT crispr_primers_loci_pkey PRIMARY KEY (crispr_oligo_id, assembly_id),
        CONSTRAINT crispr_primers_loci_assembly_id_fkey FOREIGN KEY (assembly_id)
          REFERENCES assemblies (id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
        CONSTRAINT crispr_primers_loci_chr_id_fkey FOREIGN KEY (chr_id)
          REFERENCES chromosomes (id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
        CONSTRAINT crispr_primers_loci_crispr_oligo_id_fkey1 FOREIGN KEY (crispr_oligo_id)
          REFERENCES crispr_primers(crispr_oligo_id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
        CONSTRAINT crispr_primers_loci_check CHECK (chr_start <= chr_end),
        CONSTRAINT crispr_primer_loci_chr_strand_check CHECK (chr_strand = ANY (ARRAY[1, (-1)]))
);
ALTER TABLE crispr_primers_loci
  OWNER TO lims2;

CREATE TABLE genotyping_primers_loci(
        genotyping_primer_id   INTEGER NOT NULL, 
        assembly_id         TEXT NOT NULL,
        chr_id              INTEGER NOT NULL,
        chr_start           INTEGER NOT NULL,
        chr_end             INTEGER NOT NULL,
        chr_strand          INTEGER NOT NULL,
        CONSTRAINT genotyping_primers_loci_pkey PRIMARY KEY (genotyping_primer_id, assembly_id),
        CONSTRAINT genotyping_primers_loci_assembly_id_fkey FOREIGN KEY (assembly_id)
          REFERENCES assemblies (id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
        CONSTRAINT genotyping_primers_loci_chr_id_fkey FOREIGN KEY (chr_id)
          REFERENCES chromosomes (id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
        CONSTRAINT genotyping_primers_loci_genotyping_primer_id_fkey1 FOREIGN KEY (genotyping_primer_id)
          REFERENCES genotyping_primers(id) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION,
        CONSTRAINT genotyping_primers_loci_check CHECK (chr_start <= chr_end),
        CONSTRAINT genotyping_primers_loci_chr_strand_check CHECK (chr_strand = ANY (ARRAY[1, (-1)]))
);
ALTER TABLE genotyping_primers_loci
  OWNER TO lims2;
