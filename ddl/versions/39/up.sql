ALTER TABLE crispr_loci DROP CONSTRAINT crispr_loci_pkey;
ALTER TABLE crispr_loci ADD CONSTRAINT crispr_loci_pkey PRIMARY KEY ( crispr_id, assembly_id );
ALTER TABLE crispr_loci DROP COLUMN id;
