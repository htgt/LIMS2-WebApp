use utf8;
package LIMS2::Model::Schema::Result::MiseqProjectWellExp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqProjectWellExp

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

=head1 TABLE: C<miseq_project_well_exp>

=cut

__PACKAGE__->table("miseq_project_well_exp");

=head1 ACCESSORS

=head2 miseq_well_id

  data_type: 'integer'
  is_nullable: 0

=head2 experiment

  data_type: 'text'
  is_nullable: 0

=head2 classification

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "miseq_well_id",
  { data_type => "integer", is_nullable => 0 },
  "experiment",
  { data_type => "text", is_nullable => 0 },
  "classification",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
);

=head1 RELATIONS

=head2 classification

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqClassification>

=cut

__PACKAGE__->belongs_to(
  "classification",
  "LIMS2::Model::Schema::Result::MiseqClassification",
  { id => "classification" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2017-01-23 11:34:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kY/TJoJfjgCFS/Ooc1J1xA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
