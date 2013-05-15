-- Add new column to projects table
ALTER TABLE public.projects ADD COLUMN species_id text;

-- Rename current summaries table
ALTER TABLE public.summaries RENAME TO summaries_old;

-- Create the new version of the summaries table
CREATE TABLE public.summaries (
    id serial unique primary key,
    insert_timestamp timestamp without time zone,
-- DESIGN
    design_id integer,
    design_name text,
    design_type text,
    design_species_id text,
    design_gene_id text,
    design_gene_symbol text,
    design_bacs text,
    design_phase integer,
    design_plate_name text,
    design_plate_id integer,
    design_well_name text,
    design_well_id integer,
    design_well_created_ts timestamp without time zone,
    design_well_assay_complete timestamp without time zone,
    design_well_accepted boolean,
-- INT
    int_plate_name text,
    int_plate_id integer,
    int_well_name text,
    int_well_id integer,
    int_well_created_ts timestamp without time zone,
    int_qc_seq_pass boolean,
    int_cassette_name text,
    int_backbone_name text,
    int_well_assay_complete timestamp without time zone,
    int_well_accepted boolean,
-- FINAL
    final_plate_name text,
    final_plate_id integer,
    final_well_name name,
    final_well_id integer,
    final_well_created_ts timestamp without time zone,
    final_recombinase_id text,
    final_qc_seq_pass boolean,
    final_cassette_name text,
    final_cassette_cre boolean,
    final_cassette_promoter boolean,
    final_cassette_conditional boolean,
	final_cassette_resistance text,
    final_backbone_name text,
    final_well_assay_complete timestamp without time zone,
    final_well_accepted boolean,
-- FINAL_PICK
    final_pick_plate_name text,
    final_pick_plate_id integer,
    final_pick_well_name name,
    final_pick_well_id integer,
    final_pick_well_created_ts timestamp without time zone,
    final_pick_recombinase_id text,
    final_pick_qc_seq_pass boolean,
    final_pick_cassette_name text,
    final_pick_cassette_cre boolean,
    final_pick_cassette_promoter boolean,
    final_pick_cassette_conditional boolean,
    final_pick_cassette_resistance text,
    final_pick_backbone_name text,
    final_pick_well_assay_complete timestamp without time zone,
    final_pick_well_accepted boolean,
-- DNA
    dna_plate_name text,
    dna_plate_id integer,
    dna_well_name text,
    dna_well_id integer,
    dna_well_created_ts timestamp without time zone,
    dna_qc_seq_pass boolean,
    dna_status_pass boolean,
    dna_quality text,
    dna_well_assay_complete timestamp without time zone,
    dna_well_accepted boolean,
-- EP
    ep_plate_name text,
    ep_plate_id integer,
    ep_well_name text,
    ep_well_id integer,
    ep_well_created_ts timestamp without time zone,
    ep_well_recombinase_id text,
    ep_first_cell_line_name text,
    ep_colonies_picked integer,
    ep_colonies_total integer,
    ep_colonies_rem_unstained integer,
    ep_well_assay_complete timestamp without time zone,
    ep_well_accepted boolean,
-- EP__PICK
    ep_pick_plate_name text,
    ep_pick_plate_id integer,
    ep_pick_well_name text,
    ep_pick_well_id integer,
    ep_pick_well_created_ts timestamp without time zone,
    ep_pick_well_recombinase_id text,
    ep_pick_qc_seq_pass boolean,
    ep_pick_well_assay_complete timestamp without time zone,
    ep_pick_well_accepted boolean,
-- SEP
    sep_plate_name text,
    sep_plate_id integer,
    sep_well_name text,
    sep_well_id integer,
    sep_well_created_ts timestamp without time zone,
    sep_well_recombinase_id text,
    sep_second_cell_line_name text,
    sep_well_assay_complete timestamp without time zone,
    sep_well_accepted boolean,
-- SEP_PICK
    sep_pick_plate_name text,
    sep_pick_plate_id integer,
    sep_pick_well_name text,
    sep_pick_well_id integer,
    sep_pick_well_created_ts timestamp without time zone,
    sep_pick_well_recombinase_id text,
    sep_pick_qc_seq_pass boolean,
    sep_pick_well_assay_complete timestamp without time zone,
    sep_pick_well_accepted boolean,
-- FP
    fp_plate_name text,
    fp_plate_id integer,
    fp_well_name text,
    fp_well_id integer,
    fp_well_created_ts timestamp without time zone,
    fp_well_assay_complete timestamp without time zone,
    fp_well_accepted boolean,
-- SFP
    sfp_plate_name text,
    sfp_plate_id integer,
    sfp_well_name text,
    sfp_well_id integer,
    sfp_well_created_ts timestamp without time zone,
    sfp_well_assay_complete timestamp without time zone,
    sfp_well_accepted boolean
);

-- Create the design well index
CREATE INDEX summaries_design_well_id_index ON summaries ( design_well_id );

-- Copy across the data into the new table
-- Leave id off list of columns to make it auto-generate the serial key
INSERT INTO summaries (
    insert_timestamp,
-- DESIGN
    design_id,
    design_name,
    design_type,
    design_species_id,
    design_gene_id,
    design_gene_symbol,
    design_bacs,
    design_phase,
    design_plate_name,
    design_plate_id,
    design_well_name,
    design_well_id,
    design_well_created_ts,
    design_well_assay_complete,
    design_well_accepted,
-- INT
    int_plate_name,
    int_plate_id,
    int_well_name,
    int_well_id,
    int_well_created_ts,
    int_qc_seq_pass,
    int_cassette_name,
    int_backbone_name,
    int_well_assay_complete,
    int_well_accepted,
-- FINAL
    final_plate_name,
    final_plate_id,
    final_well_name,
    final_well_id,
    final_well_created_ts,
    final_recombinase_id,
    final_qc_seq_pass,
    final_cassette_name,
    final_cassette_cre,
    final_cassette_promoter,
    final_cassette_conditional,
    final_cassette_resistance,
    final_backbone_name,
    final_well_assay_complete,
    final_well_accepted,
-- FINAL_PICK
    final_pick_plate_name,
    final_pick_plate_id,
    final_pick_well_name,
    final_pick_well_id,
    final_pick_well_created_ts,
    final_pick_recombinase_id,
    final_pick_qc_seq_pass,
    final_pick_cassette_name,
    final_pick_cassette_cre,
    final_pick_cassette_promoter,
    final_pick_cassette_conditional,
    final_pick_cassette_resistance,
    final_pick_backbone_name,
    final_pick_well_assay_complete,
    final_pick_well_accepted,
-- DNA
    dna_plate_name,
    dna_plate_id,
    dna_well_name,
    dna_well_id,
    dna_well_created_ts,
    dna_qc_seq_pass,
    dna_status_pass,
    dna_quality,
    dna_well_assay_complete,
    dna_well_accepted,
-- EP
    ep_plate_name,
    ep_plate_id,
    ep_well_name,
    ep_well_id,
    ep_well_created_ts,
    ep_well_recombinase_id,
    ep_first_cell_line_name,
    ep_colonies_picked,
    ep_colonies_total,
    ep_colonies_rem_unstained,
    ep_well_assay_complete,
    ep_well_accepted,
-- EP__PICK
    ep_pick_plate_name,
    ep_pick_plate_id,
    ep_pick_well_name,
    ep_pick_well_id,
    ep_pick_well_created_ts,
    ep_pick_well_recombinase_id,
    ep_pick_qc_seq_pass,
    ep_pick_well_assay_complete,
    ep_pick_well_accepted,
-- SEP
    sep_plate_name,
    sep_plate_id,
    sep_well_name,
    sep_well_id,
    sep_well_created_ts,
    sep_well_recombinase_id,
    sep_second_cell_line_name,
    sep_well_assay_complete,
    sep_well_accepted,
-- SEP_PICK
    sep_pick_plate_name,
    sep_pick_plate_id,
    sep_pick_well_name,
    sep_pick_well_id,
    sep_pick_well_created_ts,
    sep_pick_well_recombinase_id,
    sep_pick_qc_seq_pass,
    sep_pick_well_assay_complete,
    sep_pick_well_accepted,
-- FP
    fp_plate_name,
    fp_plate_id,
    fp_well_name,
    fp_well_id,
    fp_well_created_ts,
    fp_well_assay_complete,
    fp_well_accepted,
-- SFP
    sfp_plate_name,
    sfp_plate_id,
    sfp_well_name,
    sfp_well_id,
    sfp_well_created_ts,
    sfp_well_assay_complete,
    sfp_well_accepted
)
SELECT 
    now(),
-- DESIGN
    design_id,
    design_name,
    design_type,
-- all current rows are for Mouse
    'Mouse',
    design_gene_id,
    design_gene_symbol,
    design_bacs,
    design_phase,
    design_plate_name,
    design_plate_id,
    design_well_name,
    design_well_id,
    design_well_created_ts,
    design_well_assay_complete,
    design_well_accepted,
-- INT
    int_plate_name,
    int_plate_id,
    int_well_name,
    int_well_id,
    int_well_created_ts,
    int_qc_seq_pass,
    int_cassette_name,
    int_backbone_name,
    int_well_assay_complete,
    int_well_accepted,
-- FINAL
    final_plate_name,
    final_plate_id,
    final_well_name,
    final_well_id,
    final_well_created_ts,
    final_recombinase_id,
    final_qc_seq_pass,
    final_cassette_name,
    final_cassette_cre,
    final_cassette_promoter,
    final_cassette_conditional,
-- new resistance column can be selected using cassette name
    (SELECT resistance FROM cassettes WHERE name = final_cassette_name),
    final_backbone_name,
    final_well_assay_complete,
    final_well_accepted,
-- FINAL_PICK
    final_pick_plate_name,
    final_pick_plate_id,
    final_pick_well_name,
    final_pick_well_id,
    final_pick_well_created_ts,
    final_pick_recombinase_id,
    final_pick_qc_seq_pass,
    final_pick_cassette_name,
    final_pick_cassette_cre,
    final_pick_cassette_promoter,
    final_pick_cassette_conditional,
-- new resistance column can be selected using cassette name
    (SELECT resistance FROM cassettes WHERE name = final_pick_cassette_name),
    final_pick_backbone_name,
    final_pick_well_assay_complete,
    final_pick_well_accepted,
-- DNA
    dna_plate_name,
    dna_plate_id,
    dna_well_name,
    dna_well_id,
    dna_well_created_ts,
    dna_qc_seq_pass,
    dna_status_pass,
    dna_quality,
    dna_well_assay_complete,
    dna_well_accepted,
-- EP
    ep_plate_name,
    ep_plate_id,
    ep_well_name,
    ep_well_id,
    ep_well_created_ts,
-- new ep_recombinase column set to null for now
    null,
    ep_first_cell_line_name,
    ep_colonies_picked,
    ep_colonies_total,
    ep_colonies_rem_unstained,
    ep_well_assay_complete,
    ep_well_accepted,
-- EP__PICK
    ep_pick_plate_name,
    ep_pick_plate_id,
    ep_pick_well_name,
    ep_pick_well_id,
    ep_pick_well_created_ts,
-- new ep_pick_recombinase column set to null for now
    null,
    ep_pick_qc_seq_pass,
    ep_pick_well_assay_complete,
    ep_pick_well_accepted,
-- SEP
    sep_plate_name,
    sep_plate_id,
    sep_well_name,
    sep_well_id,
    sep_well_created_ts,
-- new sep_recombinase column set to null for now
    null,
    sep_second_cell_line_name,
    sep_well_assay_complete,
    sep_well_accepted,
-- SEP_PICK
    sep_pick_plate_name,
    sep_pick_plate_id,
    sep_pick_well_name,
    sep_pick_well_id,
    sep_pick_well_created_ts,
-- new sep_pick_recombinase column set to null for now
    null,
    sep_pick_qc_seq_pass,
    sep_pick_well_assay_complete,
    sep_pick_well_accepted,
-- FP
    fp_plate_name,
    fp_plate_id,
    fp_well_name,
    fp_well_id,
    fp_well_created_ts,
    fp_well_assay_complete,
    fp_well_accepted,
-- SFP
    sfp_plate_name,
    sfp_plate_id,
    sfp_well_name,
    sfp_well_id,
    sfp_well_created_ts,
    sfp_well_assay_complete,
    sfp_well_accepted
FROM public.summaries_old;

-- Drop the old version of the table
DROP TABLE public.summaries_old CASCADE;

-- Set up access to the new version of the table
GRANT SELECT ON summaries TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON summaries TO "[% rw_role %]";
GRANT USAGE ON SEQUENCE summaries_id_seq TO "[% rw_role %]";