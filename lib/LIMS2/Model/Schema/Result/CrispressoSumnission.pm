use utf8;
package LIMS2::Model::Schema::Result::CrispressoSumnission;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::CrispressoSumnission::VERSION = '0.528';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrispressoSumnission

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

=head1 TABLE: C<crispresso_sumnissions>

=cut

__PACKAGE__->table("crispresso_sumnissions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispresso_sumnissions_id_seq'

=head2 miseq_well_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 crispr

  data_type: 'text'
  is_nullable: 1

=head2 date_stamp

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispresso_sumnissions_id_seq",
  },
  "miseq_well_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "crispr",
  { data_type => "text", is_nullable => 1 },
  "date_stamp",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 miseq_well_experiment

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqWellExperiment>

=cut

__PACKAGE__->belongs_to(
  "miseq_well_experiment",
  "LIMS2::Model::Schema::Result::MiseqWellExperiment",
  { id => "miseq_well_experiment_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-12-04 08:43:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pgsXnIesp1GekjhDliR5fQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
