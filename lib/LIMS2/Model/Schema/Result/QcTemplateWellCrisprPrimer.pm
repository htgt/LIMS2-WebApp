use utf8;
package LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::QcTemplateWellCrisprPrimer

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

=head1 TABLE: C<qc_template_well_crispr_primers>

=cut

__PACKAGE__->table("qc_template_well_crispr_primers");

=head1 ACCESSORS

=head2 qc_run_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0

=head2 qc_template_well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 crispr_primer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0 },
  "qc_template_well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "crispr_primer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_run_id>

=item * L</qc_template_well_id>

=item * L</crispr_primer_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_run_id", "qc_template_well_id", "crispr_primer_id");

=head1 RELATIONS

=head2 crispr_primer

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimer>

=cut

__PACKAGE__->belongs_to(
  "crispr_primer",
  "LIMS2::Model::Schema::Result::CrisprPrimer",
  { crispr_oligo_id => "crispr_primer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_run

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcRun>

=cut

__PACKAGE__->belongs_to(
  "qc_run",
  "LIMS2::Model::Schema::Result::QcRun",
  { id => "qc_run_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_template_well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWell>

=cut

__PACKAGE__->belongs_to(
  "qc_template_well",
  "LIMS2::Model::Schema::Result::QcTemplateWell",
  { id => "qc_template_well_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fwifhNVCjT3VsTpdB9GUMQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
