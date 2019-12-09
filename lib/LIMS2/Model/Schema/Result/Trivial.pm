use utf8;
package LIMS2::Model::Schema::Result::Trivial;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Trivial

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
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<trivial>

=cut

__PACKAGE__->table("trivial");
__PACKAGE__->result_source_instance->view_definition(" WITH exp AS (\n         SELECT experiments.gene_id,\n            COALESCE(experiments.crispr_id, experiments.crispr_pair_id, experiments.crispr_group_id) AS crispr,\n            experiments.design_id,\n            experiments.id AS experiment_id,\n            COALESCE(trivial_offset.crispr_offset, 0) AS crispr_offset\n           FROM (experiments\n             LEFT JOIN trivial_offset ON ((trivial_offset.gene_id = experiments.gene_id)))\n          WHERE (experiments.assigned_trivial IS NULL)\n        ), trivial_crispr AS (\n         SELECT exp_1.gene_id,\n            exp_1.crispr,\n            (row_number() OVER (PARTITION BY exp_1.gene_id ORDER BY min(exp_1.experiment_id)) + exp_1.crispr_offset) AS trivial_crispr\n           FROM exp exp_1\n          GROUP BY exp_1.gene_id, exp_1.crispr, exp_1.crispr_offset\n        ), trivial_design AS (\n         SELECT exp_1.gene_id,\n            exp_1.crispr,\n            exp_1.design_id,\n            row_number() OVER (PARTITION BY exp_1.gene_id, exp_1.crispr ORDER BY min(exp_1.experiment_id)) AS trivial_design\n           FROM exp exp_1\n          GROUP BY exp_1.gene_id, exp_1.crispr, exp_1.design_id\n        )\n SELECT designs.species_id,\n    exp.experiment_id,\n    exp.gene_id,\n    exp.crispr,\n    trivial_crispr.trivial_crispr,\n    exp.design_id,\n    trivial_design.trivial_design,\n    dense_rank() OVER (PARTITION BY exp.gene_id, exp.crispr, exp.design_id ORDER BY exp.experiment_id) AS trivial_experiment\n   FROM (((exp\n     LEFT JOIN designs ON ((designs.id = exp.design_id)))\n     JOIN trivial_crispr ON (((trivial_crispr.gene_id = exp.gene_id) AND (trivial_crispr.crispr = exp.crispr))))\n     JOIN trivial_design ON ((((trivial_design.gene_id = exp.gene_id) AND (trivial_design.crispr = exp.crispr)) AND (trivial_design.design_id = exp.design_id))))\n  ORDER BY exp.gene_id, exp.crispr, exp.design_id, exp.experiment_id");

=head1 ACCESSORS

=head2 species_id

  data_type: 'text'
  is_nullable: 1

=head2 experiment_id

  data_type: 'integer'
  is_nullable: 1

=head2 gene_id

  data_type: 'text'
  is_nullable: 1

=head2 crispr

  data_type: 'integer'
  is_nullable: 1

=head2 trivial_crispr

  data_type: 'bigint'
  is_nullable: 1

=head2 design_id

  data_type: 'integer'
  is_nullable: 1

=head2 trivial_design

  data_type: 'bigint'
  is_nullable: 1

=head2 trivial_experiment

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "species_id",
  { data_type => "text", is_nullable => 1 },
  "experiment_id",
  { data_type => "integer", is_nullable => 1 },
  "gene_id",
  { data_type => "text", is_nullable => 1 },
  "crispr",
  { data_type => "integer", is_nullable => 1 },
  "trivial_crispr",
  { data_type => "bigint", is_nullable => 1 },
  "design_id",
  { data_type => "integer", is_nullable => 1 },
  "trivial_design",
  { data_type => "bigint", is_nullable => 1 },
  "trivial_experiment",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u/jFMW4bzsaZFQ3SvaAgXg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
