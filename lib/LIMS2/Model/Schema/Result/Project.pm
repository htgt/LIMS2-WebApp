use utf8;
package LIMS2::Model::Schema::Result::Project;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::Project::VERSION = '0.199';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Project

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

=head1 TABLE: C<projects>

=cut

__PACKAGE__->table("projects");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'projects_id_seq'

=head2 sponsor_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=head2 allele_request

  data_type: 'text'
  is_nullable: 0

=head2 gene_id

  data_type: 'text'
  is_nullable: 1

=head2 targeting_type

  data_type: 'text'
  default_value: 'unknown'
  is_nullable: 0

=head2 species_id

  data_type: 'text'
  is_nullable: 1

=head2 htgt_project_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "projects_id_seq",
  },
  "sponsor_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "allele_request",
  { data_type => "text", is_nullable => 0 },
  "gene_id",
  { data_type => "text", is_nullable => 1 },
  "targeting_type",
  { data_type => "text", default_value => "unknown", is_nullable => 0 },
  "species_id",
  { data_type => "text", is_nullable => 1 },
  "htgt_project_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<sponsor_gene_type_species_key>

=over 4

=item * L</sponsor_id>

=item * L</gene_id>

=item * L</targeting_type>

=item * L</species_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "sponsor_gene_type_species_key",
  ["sponsor_id", "gene_id", "targeting_type", "species_id"],
);

=head1 RELATIONS

=head2 project_alleles

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::ProjectAllele>

=cut

__PACKAGE__->has_many(
  "project_alleles",
  "LIMS2::Model::Schema::Result::ProjectAllele",
  { "foreign.project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sponsor

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Sponsor>

=cut

__PACKAGE__->belongs_to(
  "sponsor",
  "LIMS2::Model::Schema::Result::Sponsor",
  { id => "sponsor_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2014-02-07 16:49:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NWx1GMZQcu6KlFq2s3dSaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
