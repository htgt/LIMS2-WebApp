use utf8;
package LIMS2::Model::Schema::Result::MiseqWellExperiment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqWellExperiment

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

=head1 TABLE: C<miseq_well_experiment>

=cut

__PACKAGE__->table("miseq_well_experiment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_well_experiment_id_seq'

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 miseq_exp_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 classification

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=head2 frameshifted

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "miseq_well_experiment_id_seq",
  },
  "well_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "miseq_exp_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "classification",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
  "frameshifted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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

=head2 miseq_exp

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqExperiment>

=cut

__PACKAGE__->belongs_to(
  "miseq_exp",
  "LIMS2::Model::Schema::Result::MiseqExperiment",
  { id => "miseq_exp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 well

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "LIMS2::Model::Schema::Result::Well",
  { id => "well_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2017-05-22 12:34:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qrJhOB10cN0NBHvK69fYcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;