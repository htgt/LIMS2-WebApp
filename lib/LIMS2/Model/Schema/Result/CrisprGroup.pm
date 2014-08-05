use utf8;
package LIMS2::Model::Schema::Result::CrisprGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::CrisprGroup

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

=head1 TABLE: C<crispr_groups>

=cut

__PACKAGE__->table("crispr_groups");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'crispr_groups_id_seq'

=head2 gene_id

  data_type: 'text'
  is_nullable: 0

=head2 gene_type_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "crispr_groups_id_seq",
  },
  "gene_id",
  { data_type => "text", is_nullable => 0 },
  "gene_type_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 crispr_group_crisprs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprGroupCrispr>

=cut

__PACKAGE__->has_many(
  "crispr_group_crisprs",
  "LIMS2::Model::Schema::Result::CrisprGroupCrispr",
  { "foreign.crispr_group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_type

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::GeneType>

=cut

__PACKAGE__->belongs_to(
  "gene_type",
  "LIMS2::Model::Schema::Result::GeneType",
  { id => "gene_type_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 crisprs

Type: many_to_many

Composing rels: L</crispr_group_crisprs> -> crispr

=cut

__PACKAGE__->many_to_many("crisprs", "crispr_group_crisprs", "crispr");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-08-05 11:24:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ObWhOEVIrkCKQIFZhDgbNg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
