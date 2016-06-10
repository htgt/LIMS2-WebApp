insert into targeting_profiles(id) values ('homozygous'),('cre_knockin'),('ko_first');

insert into targeting_profile_alleles(targeting_profile_id,allele_type,cassette_function,mutation_type)
values
('homozygous','first','ko_first','ko_first'),
('homozygous','second','reporter_only','ko_first'),
('cre_knockin','first','cre_knock_in','cre_knock_in'),
('ko_first','first','ko_first','ko_first');

INSERT INTO schema_versions(version) VALUES (88);