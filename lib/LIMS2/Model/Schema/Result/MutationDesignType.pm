use utf8;
package LIMS2::Model::Schema::Result::MutationDesignType;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::MutationDesignType::VERSION = '0.459';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::MutationDesignType

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

=head1 TABLE: C<mutation_design_types>

=cut

__PACKAGE__->table("mutation_design_types");

=head1 ACCESSORS

=head2 mutation_id

  data_type: 'text'
  is_nullable: 0

=head2 design_type

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "mutation_id",
  { data_type => "text", is_nullable => 0 },
  "design_type",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mutation_id>

=item * L</design_type>

=back

=cut

__PACKAGE__->set_primary_key("mutation_id", "design_type");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-11-01 12:02:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kIQ44pF0SsqrVzeUuBlhvw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
