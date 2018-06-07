use utf8;
package LIMS2::Model::Schema::Result::MiseqStatus;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::MiseqStatus::VERSION = '0.506';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MiseqStatus

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

=head1 TABLE: C<miseq_status>

=cut

__PACKAGE__->table("miseq_status");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns("id", { data_type => "text", is_nullable => 0 });

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 miseq_projects_well

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqProjectWell>

=cut

__PACKAGE__->has_many(
  "miseq_projects_well",
  "LIMS2::Model::Schema::Result::MiseqProjectWell",
  { "foreign.status" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 miseq_well_experiments

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::MiseqWellExperiment>

=cut

__PACKAGE__->has_many(
  "miseq_well_experiments",
  "LIMS2::Model::Schema::Result::MiseqWellExperiment",
  { "foreign.status" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2017-07-14 16:12:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9Cbvlfyxfm1CBNlfc7K3Ag

sub as_string {
    return shift->id;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
