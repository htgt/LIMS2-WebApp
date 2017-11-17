use utf8;
package LIMS2::Model::Schema::Result::ProcessParameter;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::ProcessParameter::VERSION = '0.480';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::ProcessParameter

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

=head1 TABLE: C<process_parameters>

=cut

__PACKAGE__->table("process_parameters");

=head1 ACCESSORS

=head2 process_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 parameter_name

  data_type: 'text'
  is_nullable: 0

=head2 parameter_value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "process_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "parameter_name",
  { data_type => "text", is_nullable => 0 },
  "parameter_value",
  { data_type => "text", is_nullable => 1 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<process_parameters_process_id_parameter_name_key>

=over 4

=item * L</process_id>

=item * L</parameter_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "process_parameters_process_id_parameter_name_key",
  ["process_id", "parameter_name"],
);

=head1 RELATIONS

=head2 process

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Process>

=cut

__PACKAGE__->belongs_to(
  "process",
  "LIMS2::Model::Schema::Result::Process",
  { id => "process_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-04-27 13:02:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mwO8xSplHxY3Vhip/qUO9Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
