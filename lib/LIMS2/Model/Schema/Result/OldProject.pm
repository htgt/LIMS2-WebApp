use utf8;
package LIMS2::Model::Schema::Result::OldProject;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Schema::Result::OldProject::VERSION = '0.310';
}
## use critic


# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::OldProject

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

=head1 TABLE: C<old_projects>

=cut

__PACKAGE__->table("old_projects");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'old_projects_id_seq'

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

=head2 effort_concluded

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 recovery_comment

  data_type: 'text'
  is_nullable: 1

=head2 priority

  data_type: 'text'
  is_nullable: 1

=head2 recovery_class_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "old_projects_id_seq",
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
  "effort_concluded",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "recovery_comment",
  { data_type => "text", is_nullable => 1 },
  "priority",
  { data_type => "text", is_nullable => 1 },
  "recovery_class_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=head2 old_project_alleles

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::OldProjectAllele>

=cut

__PACKAGE__->has_many(
  "old_project_alleles",
  "LIMS2::Model::Schema::Result::OldProjectAllele",
  { "foreign.project_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 recovery_class

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::ProjectRecoveryClass>

=cut

__PACKAGE__->belongs_to(
  "recovery_class",
  "LIMS2::Model::Schema::Result::ProjectRecoveryClass",
  { id => "recovery_class_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2015-03-30 14:25:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FqviHS5WCXQHvOAXSkvyow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
