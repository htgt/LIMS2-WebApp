use utf8;
package LIMS2::Model::Schema::Result::ProjectSponsor;

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

=head2 programme_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 lab_head_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sponsor_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "priority",
  { data_type => "text", is_nullable => 1 },
  "programme_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "lab_head_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
);

=head1 RELATIONS

=head2 lab_head

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::LabHead>

=cut

__PACKAGE__->belongs_to(
  "lab_head",
  "LIMS2::Model::Schema::Result::LabHead",
  { id => "lab_head_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 programme

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Programme>

=cut

__PACKAGE__->belongs_to(
  "programme",
  "LIMS2::Model::Schema::Result::Programme",
  { id => "programme_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 project

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "LIMS2::Model::Schema::Result::Project",
  { id => "project_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 sponsor

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Sponsor>

=cut

__PACKAGE__->belongs_to(
  "sponsor",
  "LIMS2::Model::Schema::Result::Sponsor",
  { id => "sponsor_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2019-11-04 15:39:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oyyHLEgtKKKRh6js7P/g3w

__PACKAGE__->set_primary_key( qw/sponsor_id project_id/);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
