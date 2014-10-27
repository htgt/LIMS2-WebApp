use utf8;
package LIMS2::Model::Schema::Result::GeneType;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::GeneType::VERSION = '0.260';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::GeneType

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

=head1 TABLE: C<gene_types>

=cut

__PACKAGE__->table("gene_types");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 local

  data_type: 'boolean'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "local",
  { data_type => "boolean", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 crispr_groups

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprGroup>

=cut

__PACKAGE__->has_many(
  "crispr_groups",
  "LIMS2::Model::Schema::Result::CrisprGroup",
  { "foreign.gene_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::GeneDesign>

=cut

__PACKAGE__->has_many(
  "gene_designs",
  "LIMS2::Model::Schema::Result::GeneDesign",
  { "foreign.gene_type_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-08-05 11:24:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cfFwno8Q8VuzCEigo6hCgQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
