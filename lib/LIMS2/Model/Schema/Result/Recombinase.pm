use utf8;
package LIMS2::Model::Schema::Result::Recombinase;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Recombinase::VERSION = '0.387';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Recombinase

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

=head1 TABLE: C<recombinases>

=cut

__PACKAGE__->table("recombinases");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns("id", { data_type => "text", is_nullable => 0 });

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 process_recombinases

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessRecombinase>

=cut

__PACKAGE__->has_many(
  "process_recombinases",
  "LIMS2::Model::Schema::Result::ProcessRecombinase",
  { "foreign.recombinase_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_recombinases

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellRecombinase>

=cut

__PACKAGE__->has_many(
  "qc_template_well_recombinases",
  "LIMS2::Model::Schema::Result::QcTemplateWellRecombinase",
  { "foreign.recombinase_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_templates_well

Type: many_to_many

Composing rels: L</qc_template_well_recombinases> -> qc_template_well

=cut

__PACKAGE__->many_to_many(
  "qc_templates_well",
  "qc_template_well_recombinases",
  "qc_template_well",
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IT3+2l5fWyIYSqRplAiong


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
