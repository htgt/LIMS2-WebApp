use utf8;
package LIMS2::Model::Schema::Result::Species;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

LIMS2::Model::Schema::Result::Species

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

=head1 TABLE: C<species>

=cut

__PACKAGE__->table("species");

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

=head2 assemblies

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Assembly>

=cut

__PACKAGE__->has_many(
  "assemblies",
  "LIMS2::Model::Schema::Result::Assembly",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bac_libraries

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::BacLibrary>

=cut

__PACKAGE__->has_many(
  "bac_libraries",
  "LIMS2::Model::Schema::Result::BacLibrary",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 chromosomes

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Chromosome>

=cut

__PACKAGE__->has_many(
  "chromosomes",
  "LIMS2::Model::Schema::Result::Chromosome",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 default_assembly

Type: might_have

Related object: L<LIMS2::Model::Schema::Result::SpeciesDefaultAssembly>

=cut

__PACKAGE__->might_have(
  "default_assembly",
  "LIMS2::Model::Schema::Result::SpeciesDefaultAssembly",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::Design>

=cut

__PACKAGE__->has_many(
  "designs",
  "LIMS2::Model::Schema::Result::Design",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_designs

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::GeneDesign>

=cut

__PACKAGE__->has_many(
  "gene_designs",
  "LIMS2::Model::Schema::Result::GeneDesign",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_seq_projects

Type: has_many

Related object: L<LIMS2::Model::Schema::Result::QcSeqProject>

=cut

__PACKAGE__->has_many(
  "qc_seq_projects",
  "LIMS2::Model::Schema::Result::QcSeqProject",
  { "foreign.species_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-07-17 16:59:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jqMao1eC/oUZsdprlMTRWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
