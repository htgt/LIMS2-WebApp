use utf8;
package LIMS2::Model::Schema::Result::MiseqProjectWell;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqProjectWell

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

=head1 TABLE: C<miseq_project_well>

=cut

__PACKAGE__->table("miseq_project_well");

=head1 ACCESSORS

=head2 miseq_well_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_project_well_miseq_well_id_seq'

=head2 miseq_plate_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 illumina_index

  data_type: 'integer'
  is_nullable: 0

=head2 status

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "miseq_well_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_project_well_miseq_well_id_seq",
  },
  "miseq_plate_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "illumina_index",
  { data_type => "integer", is_nullable => 0 },
  "status",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</miseq_well_id>

=back

=cut

__PACKAGE__->set_primary_key("miseq_well_id");

=head1 RELATIONS

=head2 miseq_plate

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqProject>

=cut

__PACKAGE__->belongs_to(
  "miseq_plate",
  "LIMS2::Model::Schema::Result::MiseqProject",
  { id => "miseq_plate_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 status

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "LIMS2::Model::Schema::Result::MiseqStatus",
  { id => "status" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2017-01-23 11:34:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aseEhUSy9lu9oHdzMiV8nw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
