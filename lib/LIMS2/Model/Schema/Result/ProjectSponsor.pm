use utf8;
package LIMS2::Model::Schema::Result::ProjectSponsor;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::ProjectSponsor::VERSION = '0.468';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::ProjectSponsor

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

=head1 TABLE: C<project_sponsors>

=cut

__PACKAGE__->table("project_sponsors");

=head1 ACCESSORS

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sponsor_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 priority

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sponsor_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "priority",
  { data_type => "text", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<project_sponsors_key>

=over 4

=item * L</project_id>

=item * L</sponsor_id>

=back

=cut

__PACKAGE__->add_unique_constraint("project_sponsors_key", ["project_id", "sponsor_id"]);

=head1 RELATIONS

=head2 project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "LIMS2::Model::Schema::Result::Project",
  { id => "project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 sponsor

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Sponsor>

=cut

__PACKAGE__->belongs_to(
  "sponsor",
  "LIMS2::Model::Schema::Result::Sponsor",
  { id => "sponsor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-01-21 10:31:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3WOM8Z0i0NsiZHr924/6rQ

__PACKAGE__->set_primary_key( qw/sponsor_id project_id/);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
