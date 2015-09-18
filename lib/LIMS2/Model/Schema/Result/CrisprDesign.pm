use utf8;
package LIMS2::Model::Schema::Result::CrisprDesign;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrisprDesign::VERSION = '0.338';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprDesign

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

=head1 TABLE: C<crispr_designs>

=cut

__PACKAGE__->table("crispr_designs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_designs_id_seq'

=head2 crispr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 crispr_pair_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 design_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 plated

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 crispr_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_designs_id_seq",
  },
  "crispr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr_pair_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "design_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "plated",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "crispr_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_crispr_design>

=over 4

=item * L</design_id>

=item * L</crispr_id>

=back

=cut

__PACKAGE__->add_unique_constraint("unique_crispr_design", ["design_id", "crispr_id"]);

=head2 C<unique_crispr_pair_design>

=over 4

=item * L</design_id>

=item * L</crispr_pair_id>

=back

=cut

__PACKAGE__->add_unique_constraint("unique_crispr_pair_design", ["design_id", "crispr_pair_id"]);

=head1 RELATIONS

=head2 crispr

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Crispr>

=cut

__PACKAGE__->belongs_to(
  "crispr",
  "LIMS2::Model::Schema::Result::Crispr",
  { id => "crispr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 crispr_group

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprGroup>

=cut

__PACKAGE__->belongs_to(
  "crispr_group",
  "LIMS2::Model::Schema::Result::CrisprGroup",
  { id => "crispr_group_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 crispr_pair

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::CrisprPair>

=cut

__PACKAGE__->belongs_to(
  "crispr_pair",
  "LIMS2::Model::Schema::Result::CrisprPair",
  { id => "crispr_pair_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 design

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "LIMS2::Model::Schema::Result::Design",
  { id => "design_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-08-20 10:31:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TcMt+ED7VsmJZ0bjhkMt2g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
