use utf8;
package LIMS2::Model::Schema::Result::Cassette;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Cassette::VERSION = '0.371';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Cassette

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

=head1 TABLE: C<cassettes>

=cut

__PACKAGE__->table("cassettes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cassettes_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 promoter

  data_type: 'boolean'
  is_nullable: 0

=head2 phase_match_group

  data_type: 'text'
  is_nullable: 1

=head2 phase

  data_type: 'integer'
  is_nullable: 1

=head2 conditional

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 cre

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 resistance

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cassettes_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "promoter",
  { data_type => "boolean", is_nullable => 0 },
  "phase_match_group",
  { data_type => "text", is_nullable => 1 },
  "phase",
  { data_type => "integer", is_nullable => 1 },
  "conditional",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "cre",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "resistance",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cassettes_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("cassettes_name_key", ["name"]);

=head1 RELATIONS

=head2 process_cassettes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessCassette>

=cut

__PACKAGE__->has_many(
  "process_cassettes",
  "LIMS2::Model::Schema::Result::ProcessCassette",
  { "foreign.cassette_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_template_well_cassettes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcTemplateWellCassette>

=cut

__PACKAGE__->has_many(
  "qc_template_well_cassettes",
  "LIMS2::Model::Schema::Result::QcTemplateWellCassette",
  { "foreign.cassette_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kW9N7wvGyLnptNpoOp2x4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
