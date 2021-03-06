use utf8;
package LIMS2::Model::Schema::Result::Assembly;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Assembly

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

=head1 TABLE: C<assemblies>

=cut

__PACKAGE__->table("assemblies");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 0

=head2 species_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 0 },
  "species_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 amplicon_locis

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::AmpliconLoci>

=cut

__PACKAGE__->has_many(
  "amplicon_locis",
  "LIMS2::Model::Schema::Result::AmpliconLoci",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bac_clone_loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BacCloneLocus>

=cut

__PACKAGE__->has_many(
  "bac_clone_loci",
  "LIMS2::Model::Schema::Result::BacCloneLocus",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprLocus>

=cut

__PACKAGE__->has_many(
  "crispr_loci",
  "LIMS2::Model::Schema::Result::CrisprLocus",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 crispr_primers_locis

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::CrisprPrimersLoci>

=cut

__PACKAGE__->has_many(
  "crispr_primers_locis",
  "LIMS2::Model::Schema::Result::CrisprPrimersLoci",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_oligo_loci

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignOligoLocus>

=cut

__PACKAGE__->has_many(
  "design_oligo_loci",
  "LIMS2::Model::Schema::Result::DesignOligoLocus",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_targets

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::DesignTarget>

=cut

__PACKAGE__->has_many(
  "design_targets",
  "LIMS2::Model::Schema::Result::DesignTarget",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genotyping_primers_locis

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::GenotypingPrimersLoci>

=cut

__PACKAGE__->has_many(
  "genotyping_primers_locis",
  "LIMS2::Model::Schema::Result::GenotypingPrimersLoci",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 species

Type: belongs_to

Related object: L<LIMS2::Model::Schema::Result::Species>

=cut

__PACKAGE__->belongs_to(
  "species",
  "LIMS2::Model::Schema::Result::Species",
  { id => "species_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 species_default_assemblies

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::SpeciesDefaultAssembly>

=cut

__PACKAGE__->has_many(
  "species_default_assemblies",
  "LIMS2::Model::Schema::Result::SpeciesDefaultAssembly",
  { "foreign.assembly_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-01-28 08:29:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e4FFH+lNv53aY9cYycORSw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
