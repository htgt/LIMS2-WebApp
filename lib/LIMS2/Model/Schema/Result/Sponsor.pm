use utf8;
package LIMS2::Model::Schema::Result::Sponsor;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Sponsor::VERSION = '0.499';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Sponsor

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

=head1 TABLE: C<sponsors>

=cut

__PACKAGE__->table("sponsors");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 abbr

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "abbr",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<sponsors_abbr_key>

=over 4

=item * L</abbr>

=back

=cut

__PACKAGE__->add_unique_constraint("sponsors_abbr_key", ["abbr"]);

=head1 RELATIONS

=head2 old_projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::OldProject>

=cut

__PACKAGE__->has_many(
  "old_projects",
  "LIMS2::Model::Schema::Result::OldProject",
  { "foreign.sponsor_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plates

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Plate>

=cut

__PACKAGE__->has_many(
  "plates",
  "LIMS2::Model::Schema::Result::Plate",
  { "foreign.sponsor_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_sponsors

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProjectSponsor>

=cut

__PACKAGE__->has_many(
  "project_sponsors",
  "LIMS2::Model::Schema::Result::ProjectSponsor",
  { "foreign.sponsor_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2016-01-27 14:35:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NAfdR/zY2Nd6ntCBrOY/mQ

__PACKAGE__->many_to_many(
    projects => 'project_sponsors',
    'project',
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
