use utf8;
package LIMS2::Model::Schema::Result::MiseqProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::MiseqProject::VERSION = '0.503';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqProject

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

=head1 TABLE: C<miseq_projects>

=cut

__PACKAGE__->table("miseq_projects");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'miseq_projects_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 creation_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 run_id

  data_type: 'integer'
  is_nullable: 1

=head2 is_384

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
    sequence          => "miseq_projects_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "creation_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "run_id",
  { data_type => "integer", is_nullable => 1 },
  "is_384",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 miseq_experiments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqExperiment>

=cut

__PACKAGE__->has_many(
  "miseq_experiments",
  "LIMS2::Model::Schema::Result::MiseqExperiment",
  { "foreign.old_miseq_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 miseq_projects_well

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqProjectWell>

=cut

__PACKAGE__->has_many(
  "miseq_projects_well",
  "LIMS2::Model::Schema::Result::MiseqProjectWell",
  { "foreign.miseq_plate_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2017-07-26 16:29:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NyALpH6+0Z9cjQL3E2PFzA

sub as_hash {
    my $self = shift;

    my %h = (
        id      => $self->id,
        name    => $self->name,
        date    => $self->creation_date->datetime,
        384     => $self->is_384,
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
