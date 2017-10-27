use utf8;
package LIMS2::Model::Schema::Result::ProjectRecoveryClass;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::ProjectRecoveryClass::VERSION = '0.479';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::ProjectRecoveryClass

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

=head1 TABLE: C<project_recovery_class>

=cut

__PACKAGE__->table("project_recovery_class");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_recovery_class_id_seq'

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_recovery_class_id_seq",
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 old_projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::OldProject>

=cut

__PACKAGE__->has_many(
  "old_projects",
  "LIMS2::Model::Schema::Result::OldProject",
  { "foreign.recovery_class_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Project>

=cut

__PACKAGE__->has_many(
  "projects",
  "LIMS2::Model::Schema::Result::Project",
  { "foreign.recovery_class_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-03-25 11:07:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bma2ceBab5yGdGHeKM9/wQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
