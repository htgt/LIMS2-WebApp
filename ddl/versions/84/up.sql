alter table crispr_primers drop constraint "crispr_id and primer name must be unique";
alter table crispr_primers drop constraint "crispr_pair_id and primer name must be unique";
alter table crispr_primers drop constraint "crispr_group_id and and primer_name must be unique";