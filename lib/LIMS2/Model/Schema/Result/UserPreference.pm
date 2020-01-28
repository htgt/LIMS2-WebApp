use utf8;
package LIMS2::Model::Schema::Result::UserPreference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::UserPreference

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

=head1 TABLE: C<user_preferences>

=cut

__PACKAGE__->table("user_preferences");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 default_species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 default_pipeline_id

  data_type: 'text'
  default_value: 'pipeline_II'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "default_species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "default_pipeline_id",
  {
    data_type      => "text",
    default_value  => "pipeline_II",
    is_foreign_key => 1,
    is_nullable    => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id");

=head1 RELATIONS

=head2 default_pipeline

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Pipeline>

=cut

__PACKAGE__->belongs_to(
  "default_pipeline",
  "LIMS2::Model::Schema::Result::Pipeline",
  { id => "default_pipeline_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 default_species

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "default_species",
  "LIMS2::Model::Schema::Result::Species",
  { id => "default_species_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "LIMS2::Model::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K9YGrW47R3SJtjnyVBab7g
sub pipeline {
    return shift->default_pipeline_id;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
