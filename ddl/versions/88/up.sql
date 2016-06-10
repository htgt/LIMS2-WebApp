create table targeting_profiles (
    id text not null primary key
);

create table targeting_profile_alleles (
	targeting_profile_id text not null references targeting_profiles(id),
	allele_type text not null,
	cassette_function TEXT NOT NULL REFERENCES cassette_function(id),
	mutation_type text not null,
	primary key (targeting_profile_id,allele_type)
);

drop table project_alleles;

alter table projects add column targeting_profile_id text references targeting_profiles(id);

alter table projects drop CONSTRAINT gene_type_species_key;

ALTER TABLE projects
    ADD CONSTRAINT gene_type_species_profile_key UNIQUE (gene_id, targeting_type, species_id, targeting_profile_id);
