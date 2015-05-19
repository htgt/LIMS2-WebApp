use utf8;
package LIMS2::Model::Schema::Result::Summary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Summary

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<summaries>

=cut

__PACKAGE__->table("summaries");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'summaries_id_seq'

=head2 insert_timestamp

  data_type: 'timestamp'
  is_nullable: 1

=head2 design_id

  data_type: 'integer'
  is_nullable: 1

=head2 design_name

  data_type: 'text'
  is_nullable: 1

=head2 design_type

  data_type: 'text'
  is_nullable: 1

=head2 design_species_id

  data_type: 'text'
  is_nullable: 1

=head2 design_gene_id

  data_type: 'text'
  is_nullable: 1

=head2 design_gene_symbol

  data_type: 'text'
  is_nullable: 1

=head2 design_bacs

  data_type: 'text'
  is_nullable: 1

=head2 design_phase

  data_type: 'integer'
  is_nullable: 1

=head2 design_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 design_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 design_well_name

  data_type: 'text'
  is_nullable: 1

=head2 design_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 design_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 design_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 design_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 int_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 int_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 int_well_name

  data_type: 'text'
  is_nullable: 1

=head2 int_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 int_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 int_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 int_qc_seq_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 int_cassette_name

  data_type: 'text'
  is_nullable: 1

=head2 int_cassette_cre

  data_type: 'boolean'
  is_nullable: 1

=head2 int_cassette_promoter

  data_type: 'boolean'
  is_nullable: 1

=head2 int_cassette_conditional

  data_type: 'boolean'
  is_nullable: 1

=head2 int_cassette_resistance

  data_type: 'text'
  is_nullable: 1

=head2 int_backbone_name

  data_type: 'text'
  is_nullable: 1

=head2 int_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 int_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 final_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 final_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 final_well_name

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 final_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 final_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 final_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 final_qc_seq_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 final_cassette_name

  data_type: 'text'
  is_nullable: 1

=head2 final_cassette_cre

  data_type: 'boolean'
  is_nullable: 1

=head2 final_cassette_promoter

  data_type: 'boolean'
  is_nullable: 1

=head2 final_cassette_conditional

  data_type: 'boolean'
  is_nullable: 1

=head2 final_cassette_resistance

  data_type: 'text'
  is_nullable: 1

=head2 final_backbone_name

  data_type: 'text'
  is_nullable: 1

=head2 final_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 final_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 final_pick_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 final_pick_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 final_pick_well_name

  data_type: 'name'
  is_nullable: 1
  size: 64

=head2 final_pick_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 final_pick_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 final_pick_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 final_pick_qc_seq_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 final_pick_cassette_name

  data_type: 'text'
  is_nullable: 1

=head2 final_pick_cassette_cre

  data_type: 'boolean'
  is_nullable: 1

=head2 final_pick_cassette_promoter

  data_type: 'boolean'
  is_nullable: 1

=head2 final_pick_cassette_conditional

  data_type: 'boolean'
  is_nullable: 1

=head2 final_pick_cassette_resistance

  data_type: 'text'
  is_nullable: 1

=head2 final_pick_backbone_name

  data_type: 'text'
  is_nullable: 1

=head2 final_pick_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 final_pick_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 dna_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 dna_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 dna_well_name

  data_type: 'text'
  is_nullable: 1

=head2 dna_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 dna_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 dna_qc_seq_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 dna_status_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 dna_quality

  data_type: 'text'
  is_nullable: 1

=head2 dna_quality_comment

  data_type: 'text'
  is_nullable: 1

=head2 dna_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 dna_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 assembly_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 assembly_well_name

  data_type: 'text'
  is_nullable: 1

=head2 assembly_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 assembly_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 assembly_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 assembly_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 assembly_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 assembly_well_left_crispr_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 assembly_well_right_crispr_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 crispr_ep_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 crispr_ep_well_name

  data_type: 'text'
  is_nullable: 1

=head2 crispr_ep_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 crispr_ep_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 crispr_ep_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 crispr_ep_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 crispr_ep_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 crispr_ep_well_nuclease

  data_type: 'text'
  is_nullable: 1

=head2 crispr_ep_well_cell_line

  data_type: 'text'
  is_nullable: 1

=head2 ep_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 ep_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 ep_well_name

  data_type: 'text'
  is_nullable: 1

=head2 ep_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 ep_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 ep_well_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 ep_first_cell_line_name

  data_type: 'text'
  is_nullable: 1

=head2 ep_colonies_picked

  data_type: 'integer'
  is_nullable: 1

=head2 ep_colonies_total

  data_type: 'integer'
  is_nullable: 1

=head2 ep_colonies_rem_unstained

  data_type: 'integer'
  is_nullable: 1

=head2 ep_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 ep_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 ep_pick_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 ep_pick_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 ep_pick_well_name

  data_type: 'text'
  is_nullable: 1

=head2 ep_pick_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 ep_pick_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 ep_pick_well_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 ep_pick_qc_seq_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 ep_pick_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 ep_pick_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 xep_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 xep_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 xep_well_name

  data_type: 'text'
  is_nullable: 1

=head2 xep_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 xep_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 xep_well_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 xep_qc_seq_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 xep_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 xep_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 sep_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 sep_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 sep_well_name

  data_type: 'text'
  is_nullable: 1

=head2 sep_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 sep_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 sep_well_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 sep_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 sep_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 sep_pick_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 sep_pick_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 sep_pick_well_name

  data_type: 'text'
  is_nullable: 1

=head2 sep_pick_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 sep_pick_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 sep_pick_well_recombinase_id

  data_type: 'text'
  is_nullable: 1

=head2 sep_pick_qc_seq_pass

  data_type: 'boolean'
  is_nullable: 1

=head2 sep_pick_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 sep_pick_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 fp_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 fp_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 fp_well_name

  data_type: 'text'
  is_nullable: 1

=head2 fp_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 fp_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 fp_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 fp_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 piq_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 piq_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 piq_well_name

  data_type: 'text'
  is_nullable: 1

=head2 piq_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 piq_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 piq_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 piq_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 sfp_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 sfp_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 sfp_well_name

  data_type: 'text'
  is_nullable: 1

=head2 sfp_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 sfp_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 sfp_well_assay_complete

  data_type: 'timestamp'
  is_nullable: 1

=head2 sfp_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=head2 int_well_global_arm_shortening_design

  data_type: 'integer'
  is_nullable: 1

=head2 sponsor_id

  data_type: 'text'
  is_nullable: 1

=head2 to_report

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 ancestor_piq_plate_name

  data_type: 'text'
  is_nullable: 1

=head2 ancestor_piq_plate_id

  data_type: 'integer'
  is_nullable: 1

=head2 ancestor_piq_well_name

  data_type: 'text'
  is_nullable: 1

=head2 ancestor_piq_well_id

  data_type: 'integer'
  is_nullable: 1

=head2 ancestor_piq_well_created_ts

  data_type: 'timestamp'
  is_nullable: 1

=head2 ancestor_piq_well_accepted

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "summaries_id_seq",
  },
  "insert_timestamp",
  { data_type => "timestamp", is_nullable => 1 },
  "design_id",
  { data_type => "integer", is_nullable => 1 },
  "design_name",
  { data_type => "text", is_nullable => 1 },
  "design_type",
  { data_type => "text", is_nullable => 1 },
  "design_species_id",
  { data_type => "text", is_nullable => 1 },
  "design_gene_id",
  { data_type => "text", is_nullable => 1 },
  "design_gene_symbol",
  { data_type => "text", is_nullable => 1 },
  "design_bacs",
  { data_type => "text", is_nullable => 1 },
  "design_phase",
  { data_type => "integer", is_nullable => 1 },
  "design_plate_name",
  { data_type => "text", is_nullable => 1 },
  "design_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "design_well_name",
  { data_type => "text", is_nullable => 1 },
  "design_well_id",
  { data_type => "integer", is_nullable => 1 },
  "design_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "design_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "design_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "int_plate_name",
  { data_type => "text", is_nullable => 1 },
  "int_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "int_well_name",
  { data_type => "text", is_nullable => 1 },
  "int_well_id",
  { data_type => "integer", is_nullable => 1 },
  "int_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "int_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "int_qc_seq_pass",
  { data_type => "boolean", is_nullable => 1 },
  "int_cassette_name",
  { data_type => "text", is_nullable => 1 },
  "int_cassette_cre",
  { data_type => "boolean", is_nullable => 1 },
  "int_cassette_promoter",
  { data_type => "boolean", is_nullable => 1 },
  "int_cassette_conditional",
  { data_type => "boolean", is_nullable => 1 },
  "int_cassette_resistance",
  { data_type => "text", is_nullable => 1 },
  "int_backbone_name",
  { data_type => "text", is_nullable => 1 },
  "int_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "int_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "final_plate_name",
  { data_type => "text", is_nullable => 1 },
  "final_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "final_well_name",
  { data_type => "name", is_nullable => 1, size => 64 },
  "final_well_id",
  { data_type => "integer", is_nullable => 1 },
  "final_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "final_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "final_qc_seq_pass",
  { data_type => "boolean", is_nullable => 1 },
  "final_cassette_name",
  { data_type => "text", is_nullable => 1 },
  "final_cassette_cre",
  { data_type => "boolean", is_nullable => 1 },
  "final_cassette_promoter",
  { data_type => "boolean", is_nullable => 1 },
  "final_cassette_conditional",
  { data_type => "boolean", is_nullable => 1 },
  "final_cassette_resistance",
  { data_type => "text", is_nullable => 1 },
  "final_backbone_name",
  { data_type => "text", is_nullable => 1 },
  "final_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "final_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "final_pick_plate_name",
  { data_type => "text", is_nullable => 1 },
  "final_pick_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "final_pick_well_name",
  { data_type => "name", is_nullable => 1, size => 64 },
  "final_pick_well_id",
  { data_type => "integer", is_nullable => 1 },
  "final_pick_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "final_pick_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "final_pick_qc_seq_pass",
  { data_type => "boolean", is_nullable => 1 },
  "final_pick_cassette_name",
  { data_type => "text", is_nullable => 1 },
  "final_pick_cassette_cre",
  { data_type => "boolean", is_nullable => 1 },
  "final_pick_cassette_promoter",
  { data_type => "boolean", is_nullable => 1 },
  "final_pick_cassette_conditional",
  { data_type => "boolean", is_nullable => 1 },
  "final_pick_cassette_resistance",
  { data_type => "text", is_nullable => 1 },
  "final_pick_backbone_name",
  { data_type => "text", is_nullable => 1 },
  "final_pick_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "final_pick_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "dna_plate_name",
  { data_type => "text", is_nullable => 1 },
  "dna_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "dna_well_name",
  { data_type => "text", is_nullable => 1 },
  "dna_well_id",
  { data_type => "integer", is_nullable => 1 },
  "dna_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "dna_qc_seq_pass",
  { data_type => "boolean", is_nullable => 1 },
  "dna_status_pass",
  { data_type => "boolean", is_nullable => 1 },
  "dna_quality",
  { data_type => "text", is_nullable => 1 },
  "dna_quality_comment",
  { data_type => "text", is_nullable => 1 },
  "dna_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "dna_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "assembly_well_id",
  { data_type => "integer", is_nullable => 1 },
  "assembly_well_name",
  { data_type => "text", is_nullable => 1 },
  "assembly_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "assembly_plate_name",
  { data_type => "text", is_nullable => 1 },
  "assembly_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "assembly_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "assembly_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "assembly_well_left_crispr_well_id",
  { data_type => "integer", is_nullable => 1 },
  "assembly_well_right_crispr_well_id",
  { data_type => "integer", is_nullable => 1 },
  "crispr_ep_well_id",
  { data_type => "integer", is_nullable => 1 },
  "crispr_ep_well_name",
  { data_type => "text", is_nullable => 1 },
  "crispr_ep_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "crispr_ep_plate_name",
  { data_type => "text", is_nullable => 1 },
  "crispr_ep_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "crispr_ep_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "crispr_ep_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "crispr_ep_well_nuclease",
  { data_type => "text", is_nullable => 1 },
  "crispr_ep_well_cell_line",
  { data_type => "text", is_nullable => 1 },
  "ep_plate_name",
  { data_type => "text", is_nullable => 1 },
  "ep_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "ep_well_name",
  { data_type => "text", is_nullable => 1 },
  "ep_well_id",
  { data_type => "integer", is_nullable => 1 },
  "ep_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "ep_well_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "ep_first_cell_line_name",
  { data_type => "text", is_nullable => 1 },
  "ep_colonies_picked",
  { data_type => "integer", is_nullable => 1 },
  "ep_colonies_total",
  { data_type => "integer", is_nullable => 1 },
  "ep_colonies_rem_unstained",
  { data_type => "integer", is_nullable => 1 },
  "ep_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "ep_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "ep_pick_plate_name",
  { data_type => "text", is_nullable => 1 },
  "ep_pick_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "ep_pick_well_name",
  { data_type => "text", is_nullable => 1 },
  "ep_pick_well_id",
  { data_type => "integer", is_nullable => 1 },
  "ep_pick_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "ep_pick_well_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "ep_pick_qc_seq_pass",
  { data_type => "boolean", is_nullable => 1 },
  "ep_pick_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "ep_pick_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "xep_plate_name",
  { data_type => "text", is_nullable => 1 },
  "xep_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "xep_well_name",
  { data_type => "text", is_nullable => 1 },
  "xep_well_id",
  { data_type => "integer", is_nullable => 1 },
  "xep_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "xep_well_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "xep_qc_seq_pass",
  { data_type => "boolean", is_nullable => 1 },
  "xep_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "xep_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "sep_plate_name",
  { data_type => "text", is_nullable => 1 },
  "sep_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "sep_well_name",
  { data_type => "text", is_nullable => 1 },
  "sep_well_id",
  { data_type => "integer", is_nullable => 1 },
  "sep_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "sep_well_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "sep_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "sep_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "sep_pick_plate_name",
  { data_type => "text", is_nullable => 1 },
  "sep_pick_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "sep_pick_well_name",
  { data_type => "text", is_nullable => 1 },
  "sep_pick_well_id",
  { data_type => "integer", is_nullable => 1 },
  "sep_pick_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "sep_pick_well_recombinase_id",
  { data_type => "text", is_nullable => 1 },
  "sep_pick_qc_seq_pass",
  { data_type => "boolean", is_nullable => 1 },
  "sep_pick_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "sep_pick_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "fp_plate_name",
  { data_type => "text", is_nullable => 1 },
  "fp_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "fp_well_name",
  { data_type => "text", is_nullable => 1 },
  "fp_well_id",
  { data_type => "integer", is_nullable => 1 },
  "fp_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "fp_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "fp_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "piq_plate_name",
  { data_type => "text", is_nullable => 1 },
  "piq_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "piq_well_name",
  { data_type => "text", is_nullable => 1 },
  "piq_well_id",
  { data_type => "integer", is_nullable => 1 },
  "piq_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "piq_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "piq_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "sfp_plate_name",
  { data_type => "text", is_nullable => 1 },
  "sfp_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "sfp_well_name",
  { data_type => "text", is_nullable => 1 },
  "sfp_well_id",
  { data_type => "integer", is_nullable => 1 },
  "sfp_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "sfp_well_assay_complete",
  { data_type => "timestamp", is_nullable => 1 },
  "sfp_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
  "int_well_global_arm_shortening_design",
  { data_type => "integer", is_nullable => 1 },
  "sponsor_id",
  { data_type => "text", is_nullable => 1 },
  "to_report",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "ancestor_piq_plate_name",
  { data_type => "text", is_nullable => 1 },
  "ancestor_piq_plate_id",
  { data_type => "integer", is_nullable => 1 },
  "ancestor_piq_well_name",
  { data_type => "text", is_nullable => 1 },
  "ancestor_piq_well_id",
  { data_type => "integer", is_nullable => 1 },
  "ancestor_piq_well_created_ts",
  { data_type => "timestamp", is_nullable => 1 },
  "ancestor_piq_well_accepted",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-05-18 16:14:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pX0rZsB9Zk1Px+VlxWRODw


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub satisfies_cassette_function {
  my ($self, $function) = @_;

  # No point doing these checks unless we have a final_pick well
  return 0 unless defined $self->final_pick_well_id;

  ref($function) eq "LIMS2::Model::Schema::Result::CassetteFunction"
      or die "You must provide a CassetteFunction to satisfies_cassette_function. Got a ".ref($function);

  # If property, e.g. conditional, is specified true/false by CassetteFunction
  # then it must match the value of final_pick_cassette_<property>
  foreach my $property (qw(conditional promoter cre)){
    my $required_value = $function->$property;
    if (defined $required_value){
      my $summary_property = 'final_pick_cassette_'.$property;
      my $found_value = $self->$summary_property;
      return 0 unless defined($found_value) and $found_value eq $required_value;
    }
  }

  # We also need to check the recombinase status of the final_pick well
  my $final_pick_well_recom = $self->final_pick_recombinase_id;
  if (defined $function->well_has_cre){
    if ($function->well_has_cre){
      # well must have cre
      return 0 unless $final_pick_well_recom and $final_pick_well_recom =~ /cre/i;
    }
    else{
      # well must not have cre
      return 0 if $final_pick_well_recom and $final_pick_well_recom =~ /cre/i;
    }
  }

  if (defined $function->well_has_no_recombinase){
    if ($function->well_has_no_recombinase){
      return 0 if $final_pick_well_recom;
    }
    else{
      # well must have some recombinase
      return 0 unless $final_pick_well_recom;
    }
  }

  # If we haven't returned 0 yet then the well satisfies
  # the cassette function rules
  return 1;
}


__PACKAGE__->meta->make_immutable;
1;
