use utf8;
package LIMS2::Model::Schema::Result::OxygenCondition;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::OxygenCondition

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

=head1 TABLE: C<oxygen_conditions>

=cut

__PACKAGE__->table("oxygen_conditions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 process_oxygen_conditions

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProcessOxygenCondition>

=cut

__PACKAGE__->has_many(
  "process_oxygen_conditions",
  "LIMS2::Model::Schema::Result::ProcessOxygenCondition",
  { "foreign.oxygen_condition_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-04-21 10:40:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+8AiUH9xy8tktXpYOh7eCA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
