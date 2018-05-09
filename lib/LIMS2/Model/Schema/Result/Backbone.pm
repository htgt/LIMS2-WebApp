use utf8;
package LIMS2::Model::Schema::Result::Backbone;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Backbone::VERSION = '0.498';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Backbone

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

=head1 TABLE: C<backbones>

=cut

__PACKAGE__->table("backbones");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'backbones_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 antibiotic_res

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 gateway_type

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "backbones_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "antibiotic_res",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "gateway_type",
  { data_type => "text", default_value => "", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<backbones_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("backbones_name_key", ["name"]);

=head1 RELATIONS

=head2 process_backbones

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessBackbone>

=cut

__PACKAGE__->has_many(
  "process_backbones",
  "LIMS2::Model::Schema::Result::ProcessBackbone",
  { "foreign.backbone_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_backbones

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellBackbone>

=cut

__PACKAGE__->has_many(
  "qc_template_well_backbones",
  "LIMS2::Model::Schema::Result::QcTemplateWellBackbone",
  { "foreign.backbone_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CXIzUq2HCyeTfE2mRO3yZQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
