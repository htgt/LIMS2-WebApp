use utf8;
package LIMS2::Model::Schema::Result::Pipeline;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Pipeline::VERSION = '0.509';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Pipeline

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

=head1 TABLE: C<pipelines>

=cut

__PACKAGE__->table("pipelines");

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

=head2 user_preferences

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::UserPreference>

=cut

__PACKAGE__->has_many(
  "user_preferences",
  "LIMS2::Model::Schema::Result::UserPreference",
  { "foreign.default_pipeline_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-06-12 12:21:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7Zi3UprwLE4bz8lJF2unSA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
