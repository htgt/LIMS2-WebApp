use utf8;
package LIMS2::Model::Schema::Result::IndelDistributionGraph;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::IndelDistributionGraph

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

=head1 TABLE: C<indel_distribution_graph>

=cut

__PACKAGE__->table("indel_distribution_graph");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 indel_size_distribution_graph

  data_type: 'bytea'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "indel_size_distribution_graph",
  { data_type => "bytea", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::MiseqWellExperiment>

=cut

__PACKAGE__->belongs_to(
  "id",
  "LIMS2::Model::Schema::Result::MiseqWellExperiment",
  { id => "id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2018-08-07 13:44:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zapn1TSaFZjU01uSuvZrhw


sub as_hash {
    my $self = shift;

    my %h = (
        id                              => $self->id,
        indel_size_distribution_graph   => $self->indel_size_distribution_graph
    );

    return \%h;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
